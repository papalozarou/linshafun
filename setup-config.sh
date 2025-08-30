#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for checking, setting and reading setup config options.
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# Adds a variable for the setup config file stored in '~/.config/', in cases
# where the filename is generated as part of initialisation. Takes two mandatory
# arguments:
# 
# 1. "${1:?}" – the projects setup variable file name without "-setup.var"; and
# 2. "${2:?}" – the name of the config file, without "-setup.conf".
#
# Appending to a file using "cat" as per:
# 
# - https://stackoverflow.com/a/50098414
#-------------------------------------------------------------------------------
addConfigFileVar () {
  local VAR_FILE_NAME="${1:?}"
  local CONF_FILE_NAME="${2:?}"

  local VAR_FILE="$SETUP_DIR/$VAR_FILE_NAME-setup.var"
  local CONF_FILE="$CONF_FILE_NAME-setup.conf"

  cat <<EOF >> "$VAR_FILE"

#-------------------------------------------------------------------------------
# File variables.
#-------------------------------------------------------------------------------
SETUP_CONF="$SETUP_CONF_DIR/$CONF_FILE"
EOF
}

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

  printComment 'Checking for the setup config file or directory at:'
  printComment "$SETUP_CONF_DIR"

  printComment "Check for config file returned $SETUP_CONF_TF."
  printComment "Check for config directory returned $SETUP_CONF_DIR_TF."

  if [ "$SETUP_CONF_TF" = true ]; then
    printComment 'The setup config file and directory exist.'
  elif [ "$SETUP_CONF_DIR_TF" = false ]; then
    printComment 'The setup config file and directory do not exist.' true

    createSetupConfigDirectory
    createSetupConfigFile
  elif [ "$SETUP_CONF_TF" = false ]; then
    printComment 'The setup config file does not exist.' true

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
  printComment 'Listing contents of setup config file:'
  printSeparator
  cat "$SETUP_CONF"
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
# - https://stackoverflow.com/a/1478245
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

  printComment "Removing $CONF_KEY from:"
  printComment "$SETUP_CONF"

  if [ "$CONF_OPTION_TF" = true ]; then  
    sed -i '/^'"$CONF_KEY"'/d' "$SETUP_CONF"

    printComment "$CONF_KEY removed."
  else
    printComment "$CONF_KEY not found, no changes made." true
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

  printComment "Writing $CONF_KEY with value $CONF_VALUE to:"
  printComment "$SETUP_CONF"

  if [ "$CONF_OPTION_TF" = true ]; then
    local EXISTING_CONF_VALUE="$(readSetupConfigValue "$CONF_KEY")"

    printComment "$CONF_KEY already exists with value $EXISTING_CONF_VALUE." true
  fi

  if [ "$CONF_OPTION_TF" = true ] && [ "$EXISTING_CONF_VALUE" = "$CONF_VALUE" ]; then
    printComment 'No changes made.'
  elif [ "$CONF_OPTION_TF" = true ] && [ "$EXISTING_CONF_VALUE" != "$CONF_VALUE" ]; then
    printComment "Overwriting existing value with $CONF_VALUE." true

    sed -i '/^'"$CONF_KEY"'/c\'"$CONF_KEY $CONF_VALUE" "$SETUP_CONF"

    printComment 'Config written.'

    setOwner "$SUDO_USER" "$SETUP_CONF"
  elif [ "$CONF_OPTION_TF" = false ]; then
    echo "$CONF_KEY $CONF_VALUE" >> "$SETUP_CONF"

    printComment 'Config written.'

    setOwner "$SUDO_USER" "$SETUP_CONF"
  else
    printComment 'Something went wrong. Please check your setup config at:' true
    printComment "$SETUP_CONF." true
    printComment 'You may need to manually add the following to the setup config:' true
    printComment "$CONF_KEY $CONF_VALUE" true

    printScriptExiting true

    exit 1
  fi

  listSetupConfig
}