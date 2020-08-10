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

# Remind the user to add an entry to the hosts file
echo "Add the following line to /etc/hosts if needed";
echo "$virtual_host_ip_address     $virtual_host_name";
