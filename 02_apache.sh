##### APACHE ###############################################################

# Import the install function
. ./function_install.sh;

# Get the option values from the command line
declare virtual_host_name="localdev";
declare virtual_host_ip_address="127.0.200.1";
declare parameter_flag;

while [ $# -gt 0 ];
do
  parameter_flag=$1;
  shift;

  case $parameter_flag in
    -n | --name )
      virtual_host_name=$1;;
    -i | --ip-address )
      virtual_host_ip_address=$1;;
  esac

  shift;
done;

# Validate the option values
if [[ ! $virtual_host_name =~ ^[a-z0-9\-]+$ ]];
then
  echo "Virtual host name \"$virtual_host_name\" must only contain letters, numbers, and dashes";
  exit 1;
fi

# TO-DO: Validate the IP address
#if [[ ! $virtual_host_ip_address =~ ([12]?[1-9]?[0-9]\.){3}([12]?[1-9]?[0-9]) ]];
#then
#  echo "Virtual host IP address \"$virtual_host_ip_address\" must be correctly formatted";
#  exit 2;
#fi

echo "Virtual host name is $virtual_host_name";
echo "Virtual host IP address is $virtual_host_ip_address";

# TO-DO: Ask for confirmation

# Copy the configuration file template to a temp file
cp ./apache_template.conf ./$virtual_host_name.conf

## Update the value of the IP address in the temp file
sed -i "s/~IP_ADDRESS~/$virtual_host_ip_address/" $virtual_host_name.conf;

# Create the document root directory in /var/www if needed
declare virtual_host_document_root_path="/var/www/$virtual_host_name";

if [ ! -d $virtual_host_document_root_path ];
then
  echo "Creating $virtual_host_name document root directory";
  mkdir $virtual_host_document_root_path;
else
  echo "$virtual_host_name document root directory already exists";
fi

# Install Apache
install apache2;

# Disable the virtual host site if it's running
if apache2ctl -S -e emerg | grep -o -q $virtual_host_name;
then
  echo "Disabling $virtual_host_name site";
  a2dissite -q $virtual_host_name;
fi

# TO-DO: Make this an option
## Disable the 000-default site if it's running
#if apache2ctl -S -e emerg | grep -o -q 000-default;
#then
#  echo "Disabling 000-default virtual host";
#  a2dissite -q 000-default;
#fi

# Set the global ServerName if needed
declare -r apache_global_conf="/etc/apache2/apache2.conf";

# Enable mod_rewrite
a2enmod rewrite;

if ! grep -q ServerName $apache_global_conf;
then
  echo "Setting global ServerName to localdev"
  echo "ServerName $virtual_host_name" >> $apache_global_conf;
else
  echo "Global ServerName is already set"
fi

# Copy the configuration file to Apache's available sites directory
mv "$virtual_host_name.conf" "/etc/apache2/sites-available/$virtual_host_name.conf";

# Enable the virtual host site
echo "Enabling $virtual_host_name virtual host";
a2ensite -q $virtual_host_name;

# Restart the Apache service
echo "Restarting Apache";
service apache2 restart;

# Get the user and group that Apache is running as
declare apache_config=$(apachectl -t -D DUMP_RUN_CFG);

declare user_regex="User\:[[:space:]]name=\"([A-Za-z0-9\-]+)\"";
declare apache_user;

if [[ $apache_config =~ $user_regex ]];
then
  apache_user=${BASH_REMATCH[1]};
  echo "Apache user is $apache_user";
else
  echo "Can't find Apache user";
fi

declare group_regex="Group\:[[:space:]]name=\"([A-Za-z0-9\-]+)\"";
declare apache_group;

if [[ $apache_config =~ $group_regex ]];
then
  apache_group=${BASH_REMATCH[1]};
  echo "Apache group is $apache_group";
else
  echo "Can't find Apache group";
fi

if [[ ! -z $apache_user && ! -z $apache_group ]];
then
  # Make the Apache user and group the owner of the document root
  echo "Making $apache_user:$apache_group the owner of $virtual_host_document_root_path";
  chown $apache_user:$apache_group -R $virtual_host_document_root_path;

  # Make the document root writable for the Apache user's group
  echo "Making $virtual_host_document_root_path writable for $apache_group group";
  chmod g+w -R $virtual_host_document_root_path;
fi

# Check to see if the current user is part of the Apache user's group
declare current_user="${SUDO_USER:-${USER}}";
declare current_user_groups=$(groups $current_user);

# TO-DO: Make this resilient to bad replies
if [[ ! $current_user_groups =~ $apache_group ]];
then
  read -p "Add $current_user to $apache_group group? " user_input;

  if [ $user_input = "y" ];
  then
    usermod -a -G $apache_group $current_user;
  fi
fi

# Remind the user to add an entry to the hosts file
echo "Add the following line to /etc/hosts if needed";
echo "$virtual_host_ip_address     $virtual_host_name";
