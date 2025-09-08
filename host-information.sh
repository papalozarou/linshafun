#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for getting OS information.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Compares the current Linux distribution version against a given version. Takes 
# one mandatory argument:
#
# 1. "${1:?}" – the OS version number to compare to.
#
# The function returns true if the current OS is less than or equal to the given 
# version, and false if it is higher.
#
# N.B.
# As shell can't compare floating decimal points, both the comparison OS and the
# current OS are stripped to their major version number. As per:
#
# - https://unix.stackexchange.com/a/569768
#-------------------------------------------------------------------------------
compareOsVersion () {
  local COMPARISON_OS="$(echo "${1:?}" | cut -d'.' -f1)"
  local CURRENT_OS="$(getOsVersion | cut -d'.' -f1)"

  if [ "$CURRENT_OS" -gt "$COMPARISON_OS" ] ; then
    echo false
  else
    echo true
  fi
}

#-------------------------------------------------------------------------------
# Gets the Linux distribution the host machine is running, e.g. ubuntu, debian,
# etc.
#-------------------------------------------------------------------------------
getOsDistribution () {
  local OS_DISTRIBUTION="$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')"

  echo "$OS_DISTRIBUTION"
}


#-------------------------------------------------------------------------------
# Gets the Linux distribution version number the host machine is running.
#-------------------------------------------------------------------------------
getOsVersion () {
  local OS_VERSION="$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')"

  echo "$OS_VERSION"
}

#-------------------------------------------------------------------------------
# Gets the Linux kernal version number the host machine is running.
#-------------------------------------------------------------------------------
getKernalVersion () {
  local KERNAL_VERSION="$(uname -r)"

  echo "$KERNAL_VERSION"
}