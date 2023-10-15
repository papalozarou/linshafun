#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for checking, setting and reading setup config options.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Check for a current setup config file and directory. If both exist, do 
# nothing. If either doesn't exist, create them. There are three possibilities:
# 
# 1. the setup config file exists so the directory must exist;
# 2. the setup config directory exists and the file doesn't; or
# 3. the setup config directory doesn't exist so the file can't.
#-------------------------------------------------------------------------------
checkForSetupConfigFileAndDir () {
  local SETUP_CONF_TF="$(checkForDirectory "$SETUP_CONF")"
  local SETUP_CONF_DIR_TF="$(checkForDirectory "$SETUP_CONF_DIR")"

  echoComment 'Checking for the setup config file or directory at:'
  echoComment "$SETUP_CONF_DIR"

  if [ "$SETUP_CONF_TF" = true ]; then
    echoComment 'The setup config file and directory exist.'
  elif [ "$SETUP_CONF_TF" = false ] && [ "$SETUP_CONF_DIR_TF" = true ]; then
    echoComment 'The setup config file does not exist.'

    createSetupConfigFile
  elif [ "$SETUP_CONF_DIR_TF" = false]; then
    echoComment 'The setup config file and directory do not exist.'

    createSetupConfigDirectory
    createSetupConfigFile
  fi

  listDirectories "$SETUP_CONF_DIR"
}

#-------------------------------------------------------------------------------
# Checks for a setup config option. Takes one mandatory argument:
# 
# 1. "${1:?}" – the key of the config option.
#
# The function returns true or false depending on if the config option is 
# present in the config file.
# 
# N.B.
# The config option key must be formatted exactly as in the config option file,
# i.e. using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
#-------------------------------------------------------------------------------
checkSetupConfigOption () {
  local CONFIG_KEY="${1:?}"
  local CONFIG="$(grep "$CONFIG_KEY" "$SETUP_CONF")"

  if [ -z "$CONFIG" ]; then
    echo false
  else
    echo true
  fi
}

#-------------------------------------------------------------------------------
# Creates the setup config directory and sets the correct ownership.
#-------------------------------------------------------------------------------
createSetupConfigDirectory () {
  createDirectory "$SETUP_CONF_DIR"
  setOwner "$SUDO_USER" "$CONF_DIR"
  setOwner "$SUDO_USER" "$SETUP_CONF_DIR"
}

#-------------------------------------------------------------------------------
# Creates the setup config file and sets the correct permissions and ownership.
#-------------------------------------------------------------------------------
createSetupConfigFile () {
  createFiles "$SETUP_CONF"
  setPermissions 600 "$SETUP_CONF"
  setOwner "$SUDO_USER" "$SETUP_CONF"
}

#-------------------------------------------------------------------------------
# Gets a service name from a given config key. Takes one mandatory argument:
# 
# 1. "${1:?}" – the config option key to be used.
#
# If the config key contains a service, "$SERVICE" is returned. If not, nothing
# is returned.
# 
# N.B.
# The config option key must be formatted exactly as in the config option file,
# i.e. using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
#-------------------------------------------------------------------------------
getServiceFromConfigKey () {
  local CONFIG_KEY="${1:?}"

  if [ -z "${CONFIG_KEY##configured*}" ]; then
    local SERVICE="$(changeCase "${CONFIG_KEY#'configured'}" 'lower')"

    echo "$SERVICE"
  fi
}

#-------------------------------------------------------------------------------
# Reads and returns a setup config option. Takes one mandatory argument:
# 
# 1. "${1:?}" – the key of the config option.
# 
# The config line is read by "grep" and stored in "$CONFIG". This is split by 
# "set" into it's key, "$1", and it's value, "$2" – the "-f" flag prevents pathname 
# expansion for safety. Taken from:
#
# https://stackoverflow.com/a/1478245
# 
# N.B.
# "$CONFIG" is not quoted as we need word splitting in this instance. 
#
# The config option key must be formatted exactly as in the config option file,
# i.e. using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
#-------------------------------------------------------------------------------
readSetupConfigOption () {
  local CONFIG_KEY="${1:?}"
  local CONFIG="$(grep "$CONFIG_KEY" "$SETUP_CONF")"

  set -f $CONFIG
  
  echo "$2"
}

#-------------------------------------------------------------------------------
# Writes a setup config option. Takes two mandatory arguments:
#
# 1. "${1:?}" – the key of the config option; and
# 2. "${2:?}" – the value of the config option.
#
# Once the config option is written, the file ownership is set to "$SUDO_USER".
# 
# N.B.
# The config option key must be formatted exactly as in the config option file,
# i.e. using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
#-------------------------------------------------------------------------------
writeSetupConfigOption () {
  local CONF_KEY="${1:?}"
  local CONF_VALUE="${2:?}"

  echoComment "Writing $CONF_KEY to:"
  echoComment "$SETUP_CONF"
  echo "$CONF_KEY $CONF_VALUE" >> "$SETUP_CONF"
  echoComment 'Config written.'

  setOwner "$SUDO_USER" "$SETUP_CONF"
}
