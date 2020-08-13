# Import the install function
. ./function_install.sh;

# Get the option values from the command line
# TO-DO: Figure out how to get the latest version without asking the user
# TO-DO: Prompt the user for the PHP version if it isn't specified
declare version_to_install="";
declare parameter_flag;

while [ $# -gt 0 ];
do
  parameter_flag=$1;
  shift;

  case $parameter_flag in
    -v | --version )
      version_to_install=$1;;
  esac

  shift;
done;

# Validate the option values
if [[ -z $version_to_install ]];
then
  echo "Installation version missing; set using -v option";
  exit 1;
fi

# Add the PHP PPA
apt-add-repository -q "ppa:ondrej/php";
apt update -q;

# Install the latest version of PHP if needed
declare package_name="php$version_to_install";
install $package_name;

# Install Composer if needed
install composer;

# Install Laravel if needed
install "php$version_to_install-xml";
install "php$version_to_install-zip";
composer global require laravel/installer;
install npm;
