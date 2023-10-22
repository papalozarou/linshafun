#!/bin/sh

#-------------------------------------------------------------------------------
# Functions to read the host IP and generate or check port numbers.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Check to see if a generated port number has already been used for another 
# service. Takes two mandatory arguement:
# 
# 1. "${1:?}" – the port to check; and
# 2. "${2:?}" – the config option key for the service to check against.
# 
# N.B.
# The config option key must be formatted exactly as in the config option file,
# i.e. using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
#-------------------------------------------------------------------------------
checkAgainstExistingPortNumber () {
  local PORT="${1:?}"
  local SERVICE="${2:?}Port"
  local SERVICE_PORT="$(readSetupConfigValue "$SERVICE")"

  if [ "$PORT" = "$SERVICE_PORT" ]; then
    echo true
  else 
    echo false
  fi
}

#-------------------------------------------------------------------------------
# Generates a port number then checks against a given service. If the check
# returns true, re-run the function to generate a new port number. If the check 
# returns false, return the generated port number. Takes one mandatory argument:
# 
# 1. "{1:?}" – the service to check against.
#-------------------------------------------------------------------------------
generateAndCheckPort () {
  local CHECK_AGAINST="${1:?}"
  local PORT_NO="$(generatePortNumber)"
  local PORT_TF="$(checkAgainstExistingPortNumber "$PORT_NO" "$CHECK_AGAINST")"

  if [ "$PORT_TF" = true ]; then
    echoComment "Port check returned $PORT_TF. Re-running to generate" 
    echoComment 'another port number.'
    generateAndCheckPort
  elif [ "$PORT_TF" = false ]; then
    echo "$PORT_NO"    
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
# Reads and returns the IP address of the host machine.
#-------------------------------------------------------------------------------
readIpAddress () {
  local IP_ADDRESS="$(ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+')"

  echo "$IP_ADDRESS"
}