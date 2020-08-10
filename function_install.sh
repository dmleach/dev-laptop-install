function install () {
  if ! dpkg -s $1 >/dev/null 2>&1; 
  then
    echo "Installing $1";
    apt -qq install $1;
  else
    echo "Package $1 is already installed";
  fi
}
