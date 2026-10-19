#!/bin/sh

#-------------------------------------------------------------------------------
# Functions to read the host IP and generate or check port numbers.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Check to see if a generated port number has already been used for another 
# service. Takes two mandatory argument:
# 
# 1. "${1:?}" – the port to check; and
# 2. "${2:?}" – the service to check against.
# 
# Returns 0 if the port matches the service's existing port, 1 if not.
# 
# N.B.
# The config option key must be formatted exactly as in the config option file,
# i.e. using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
#-------------------------------------------------------------------------------
checkAgainstExistingPortNumber () {
  local COMPARISON_PORT="${1:?}"
  local SERVICE="${2:?}Port"
  local EXISTING_PORT="$(readSetupConfigValue "$SERVICE")"

  [ "$COMPARISON_PORT" = "$EXISTING_PORT" ]
}

#-------------------------------------------------------------------------------
# Generates a port number then checks against a given service. If the check
# returns 0, re-run the function to generate a new port number. If the check 
# returns 1, return the generated port number. Takes one mandatory argument:
# 
# 1. "${1:?}" – the service to check against.
#-------------------------------------------------------------------------------
generateAndCheckPort () {
  local SERVICE="${1:?}"
  local PORT="$(generatePortNumber)"

  if checkAgainstExistingPortNumber "$PORT" "$SERVICE"; then
    printComment "Port $PORT is already used by $SERVICE. Re-running to generate another port number." 'warning'
    generateAndCheckPort "$SERVICE"
  else
    echo "$PORT"    
  fi
}

#-------------------------------------------------------------------------------
# Generates a random port number between 2000 and 65000 inclusive, as per:
#
# - https://unix.stackexchange.com/questions/140750/generate-random-numbers-in-specific-range
#-------------------------------------------------------------------------------
generatePortNumber () {
  local PORT="$(shuf -i 2000-65000 -n 1)"

  echo "$PORT"
}

#-------------------------------------------------------------------------------
# Gets the name of a given network interface, using "nmcli". Takes one mandatory 
# argument:
# 
# 1. "${1:?}" – the interface id, e.g. eth0, enp3s0, etc.
# 
# N.B.
# If "nmcli" is not installed this function will fail silently.
#-------------------------------------------------------------------------------
getInterfaceName () {
  local INTERFACE_ID="${1:?}"
  local INTERFACE_NAME="$(nmcli -g GENERAL.CONNECTION device show "$INTERFACE_ID")"

  echo "$INTERFACE_NAME"
}

#-------------------------------------------------------------------------------
# Reads and returns the IP address of the host machine.
#-------------------------------------------------------------------------------
readIpAddress () {
  local IP_ADDRESS="$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')"

  echo "$IP_ADDRESS"
}