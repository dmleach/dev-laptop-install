# Import the install function
. ./function_install.sh;

# Get the option values from the command line
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
if [[ $version_to_install -eq "" ]];
then
  echo "Installation version missing; set using -v option";
  exit 1;
fi

# Install curl if needed
install curl;

# Install the latest version of PHP if needed
# TO-DO: Figure out how to ask for the latest version, whatever it is
declare package_name="php$version_to_install";
install $package_name;
