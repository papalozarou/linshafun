#!/bin/sh

#-------------------------------------------------------------------------------
# Functions to check, install and remove packages.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Checks whether a given package is already installed. Takes one mandatory
# argument:
# 
# 1. "${1:?}" – the package to be checked. 
# 
# Returns false if the package is not installed, returns true if the package is 
# installed. As per:
#
# - https://stackoverflow.com/a/7522866
# 
# N.B.
# This function explicitly checks a single package to allow for a simple true or 
# false check.
#-------------------------------------------------------------------------------
checkForPackage () {
  local PACKAGE="${1:?}"

  if ! type "$PACKAGE" > /dev/null; then
    echo false
  else
    echo true   
  fi
}

#-------------------------------------------------------------------------------
# Checks if one or more packages are installed and if not the packages are 
# installed. Takes one or more mandatory arguments:
# 
# 1. "$@" – the package or packages to be installed.
#-------------------------------------------------------------------------------
checkForPackagesAndInstall () {
  printComment 'Starting installation of the following packages:'
  printComment "$@"

  for PACKAGE in "$@"; do
    local PACKAGE_TF="$(checkForPackage "$PACKAGE")"

    printCheckResult 'to see if' "$PACKAGE" 'is installed' "$PACKAGE_TF"

    if [ "$PACKAGE_TF" = true ]; then
      printComment "You have already installed $PACKAGE."
    elif [ "$PACKAGE_TF" = false ]; then
      printComment "You need to install $PACKAGE." 'warning'
      installRemovePackages "install" "$PACKAGE"
    fi
  done
}

#-------------------------------------------------------------------------------
# Checks if one or more packages are installed and if they are the packages is 
# removed. Takes one or more mandatory arguments:
# 
# 1. "$@" – the package or packages to be removed.
#-------------------------------------------------------------------------------
checkForPackagesAndRemove () {
  printComment 'Starting removal of the following packages:'
  printComment "$@"

  for PACKAGE in "$@"; do
    local PACKAGE_TF="$(checkForPackage "$PACKAGE")"
    
    printCheckResult 'to see if' "$PACKAGE" 'is installed' "$PACKAGE_TF"

    if [ "$PACKAGE_TF" = true ]; then
      printComment "You need to remove $PACKAGE." 'warning'
      installRemovePackages "remove" "$PACKAGE"
    elif [ "$PACKAGE_TF" = false ]; then
      printComment "You have already removed $PACKAGE."
    fi
  done
}

#-------------------------------------------------------------------------------
# Installs or removes a given package. Takes at least two or more arguments:
# 
# 1. "${1:?}" - the action to be taken, either "install" or "remove"
# 2. "$i" – one or more packages to be installed.
# 
# The function tests to see if the an accepted value has been passed as the
# first argument then stores it as the action to be taken. It then shifts the 
# argument position by 1, and loops through each of the rest of the arguments. 
# As per:
# 
# - https://unix.stackexchange.com/a/225951
#-------------------------------------------------------------------------------
installRemovePackages () {
  if [ "${1:?}" = 'install' ] || [ "${1:?}" = 'remove' ]; then
    local ACTION="${1:?}"
  
    shift
  else
    
    printScriptExiting
    
    exit 1
  fi

  for i; do
    printComment "Performing $ACTION for $i."
    printSeparator
    apt "$ACTION" "$i" -y
    printSeparator
    printComment "Completed $ACTION for $i"
  done
}

#-------------------------------------------------------------------------------
# Updates and upgrades installed packages.
#-------------------------------------------------------------------------------
updateUpgrade () {
  printComment 'Updating and upgrading packages.'
  printSeparator
  apt update && apt upgrade -y
  printSeparator
  printComment 'Packages updated and upgraded.'
}