# Create the log file if it doesn't already exist
declare -r log_file="install.log";
touch $log_file;

# Add a header for this installation log
declare -r start_time=$(date '+%d/%m/%Y %H:%M');
echo -e "\n\nInstallation began at $start_time" >> $log_file;

function output () {
  echo $1 | tee -a $log_file;
}

# Import the install function
. ./function_install.sh;

#declare -i exit_code;

# Declare an array with the scripts to run
declare -a install_scripts=("01_graphics.sh" "02_apache.sh");

# Run the scripts
declare -i exit_code;
declare install_script_command;

for install_script in "${install_scripts[@]}"
do
  output "Running script $install_script";

  # TO-DO: Capture echoes from child script and write them to the log
  install_script_command="bash ./$install_script";
  eval $install_script_command;

  if [ $? -eq 0 ];
  then
    output "$install_script returned error code 0; continuing";
  else
    output "$install_script returned error code $exit_code; aborting";
    exit $exit_code;
  fi

  output "";
done

