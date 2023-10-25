#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for checking, setting and reading setup config options.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Check for a current setup config file and directory. If both exist, do 
# nothing. If either doesn't exist, create them. There are three possibilities:
# 
# 1. the setup config file exists so the directory must exist;
# 2. the setup config directory doesn't exist so the file can't; or
# 3. the setup config directory exists and the file doesn't.
#-------------------------------------------------------------------------------
checkForSetupConfigFileAndDir () {
  local SETUP_CONF_TF="$(checkForFileOrDirectory "$SETUP_CONF")"
  local SETUP_CONF_DIR_TF="$(checkForFileOrDirectory "$SETUP_CONF_DIR")"

  echoComment 'Checking for the setup config file or directory at:'
  echoComment "$SETUP_CONF_DIR"

  echoComment "Check for config file returned $SETUP_CONF_TF."
  echoComment "Check for config directory returned $SETUP_CONF_DIR_TF."

  if [ "$SETUP_CONF_TF" = true ]; then
    echoComment 'The setup config file and directory exist.'
  elif [ "$SETUP_CONF_DIR_TF" = false ]; then
    echoComment 'The setup config file and directory do not exist.'

    createSetupConfigDirectory
    createSetupConfigFilegit pu
  elif [ "$SETUP_CONF_TF" = false ]; then
    echoComment 'The setup config file does not exist.'

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
# The config key must be formatted exactly as in the config option file, i.e. 
# using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
#-------------------------------------------------------------------------------
checkForSetupConfigOption () {
  local CONF_KEY="${1:?}"
  local CONF_OPTION="$(grep "$CONF_KEY" "$SETUP_CONF")"

  if [ -z "$CONF_OPTION" ]; then
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
# 1. "${1:?}" – the config key to be used.
#
# If the config key contains a service, "$SERVICE" is returned. If not, nothing
# is returned.
# 
# N.B.
# The config key must be formatted exactly as in the config option file, i.e. 
# using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
#-------------------------------------------------------------------------------
getServiceFromConfigKey () {
  local CONF_KEY="${1:?}"

  if [ -z "${CONF_KEY##configured*}" ]; then
    local SERVICE="$(changeCase "${CONF_KEY#'configured'}" 'lower')"

    echo "$SERVICE"
  fi
}

#-------------------------------------------------------------------------------
# Lists the contents of the setup config file
#-------------------------------------------------------------------------------
listSetupConfig () {
  echoComment 'Listing contents of setup config file:'
  echoSeparator
  cat "$SETUP_CONF"
  echoSeparator
}

#-------------------------------------------------------------------------------
# Reads and returns a setup config value. Takes one mandatory argument:
# 
# 1. "${1:?}" – the key of the config value.
# 
# The config line is read by "grep" and stored in "$CONFIG". This is split by 
# "set" into it's key, "$1", and it's value, "$2" – the "-f" flag prevents 
# pathname expansion for safety. Taken from:
#
# https://stackoverflow.com/a/1478245
# 
# N.B.
# "$CONFIG" is not quoted as we need word splitting in this instance. 
#
# The config key must be formatted exactly as in the config option file, i.e. 
# using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
#-------------------------------------------------------------------------------
readSetupConfigValue () {
  local CONF_KEY="${1:?}"
  local CONF_OPTION="$(grep "$CONF_KEY" "$SETUP_CONF")"

  set -f $CONF_OPTION
  
  echo "$2"
}

#-------------------------------------------------------------------------------
# Removes a setup config option. Takes one mandatory argument:
# 
# 1. "${1:?}" – the key of the config option.
# 
# N.B.
# The config key must be formatted exactly as in the config option file, i.e. 
# using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
#-------------------------------------------------------------------------------
removeSetupConfigOption () {
  local CONF_KEY="${1:?}"
  local CONF_OPTION_TF="$(checkForSetupConfigOption "$CONF_KEY")"

  echoComment "Removing $CONF_KEY from:"
  echoComment "$SETUP_CONF"

  if [ "$CONF_OPTION_TF" = true ]; then  
    sed -i '/^'"$CONF_KEY"'/d' "$SETUP_CONF"

    echoComment "$CONF_KEY removed."
  else
    echoComment "$CONF_KEY not found, no changes made."
  fi

  listSetupConfig
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
# The config key must be formatted exactly as in the config option file, i.e. 
# using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
#-------------------------------------------------------------------------------
writeSetupConfigOption () {
  local CONF_KEY="${1:?}"
  local CONF_VALUE="${2:?}"
  local CONF_OPTION_TF="$(checkForSetupConfigOption "$CONF_KEY")"

  echoComment "Writing $CONF_KEY with value $CONF_VALUE to:"
  echoComment "$SETUP_CONF"

  if [ "$CONF_OPTION_TF" = true ]; then
    local EXISTING_CONF_VALUE="$(readSetupConfigValue "$CONF_KEY")"

    echoComment "$CONF_KEY already exists with value $EXISTING_CONF_VALUE."
  fi

  if [ "$CONF_OPTION_TF" = true ] && [ "$EXISTING_CONF_VALUE" = "$CONF_VALUE" ]; then
    echoComment 'No changes made.'
  elif [ "$CONF_OPTION_TF" = true ] && [ "$EXISTING_CONF_VALUE" != "$CONF_VALUE" ]; then
    echoComment "Overwriting existing value with $CONF_VALUE."

    sed -i '/^'"$CONF_KEY"'/c\'"$CONF_KEY $CONF_VALUE" "$SETUP_CONF"

    echoComment 'Config written.'

    setOwner "$SUDO_USER" "$SETUP_CONF"
  elif [ "$CONF_OPTION_TF" = false ]; then
    echo "$CONF_KEY $CONF_VALUE" >> "$SETUP_CONF"

    echoComment 'Config written.'

    setOwner "$SUDO_USER" "$SETUP_CONF"
  else
    echoComment 'Something went wrong. Please check your setup config at:'
    echoComment "$SETUP_CONF."
    echoComment 'You may need to manually add the following to the setup config:'
    echoComment "$CONF_KEY $CONF_VALUE"

    echoScriptExiting true

    exit 1
  fi

  listSetupConfig
}