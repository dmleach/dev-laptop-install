# Create the log file if it doesn't already exist
declare -r log_file="install.log";
touch $log_file;

# Add a header for this installation log
declare -r start_time=$(date '+%d/%m/%Y %H:%M');
echo -e "\n\nInstallation began at $start_time" >> $log_file;

# Declare the install function
function install () {
  if ! dpkg -s $1 >/dev/null 2>&1; 
  then
    tput setaf 2;
    echo "Installing $1" | tee -a $log_file;
    apt -qq install $1 >> install.log;
  else
    tput setaf 4;
    echo "Package $1 is already installed" | tee -a $log_file;
  fi

  tput setaf 9;
}

# These packages are required to install the graphics driver
install gcc;
install make;

# TO-DO: Save graphics driver to repository
# TO-DO: Automatically install graphics driver

# Install Apache
install apache2;
