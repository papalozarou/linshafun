#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for checking, setting and reading setup config options.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds a variable to "./setup/[project-name]-setup.var". Takes three mandatory
# arguments:
# 
# 1. "${1:?}" – the project's setup variable file name, without "-setup.var" and 
#    excluding the directory path;
# 2. "${2:?}" – the name of the variable to be added; and
# 3. "${3:?}" – the value of the variable to be added.
#
# Appending to a file using "cat" as per:
# 
# - https://stackoverflow.com/a/50098414
#-------------------------------------------------------------------------------
addSetupVar () {
	local VAR_FILE_NAME="${1:?}"
	local VAR_NAME="${2:?}"
	local VAR_VALUE="${3:?}"
  local VAR_FILE_PATH="$SETUP_DIR_PATH/$VAR_FILE_NAME-setup.var"

	printComment 'Adding $'"$VAR_NAME variable to:"
	printComment "$VAR_FILE_PATH"
	
  cat <<EOF >> "$VAR_FILE_PATH"
$VAR_NAME="$VAR_VALUE"
EOF

	printSeparator
	
	if grep "$VAR_NAME" "$VAR_FILE_PATH"; then
		printSeparator
		printComment '$'"$VAR_NAME variable added."
	else
    printComment 'There was a problem adding the $'"$VAR_NAME variable. Please check the variable file at:" 'error'
    printComment "$VAR_FILE_PATH" 'error'

		exit 1
	fi
	
	reloadVarFile "$VAR_FILE_PATH"
}

#-------------------------------------------------------------------------------
# Check for a current setup config file and directory. If both exist, do 
# nothing. If either doesn't exist, create them. There are three possibilities:
# 
# 1. the setup config file exists so the directory must exist;
# 2. the setup config directory doesn't exist so the file can't; or
# 3. the setup config directory exists and the file doesn't.
#-------------------------------------------------------------------------------
checkForAndCreateSetupConfigFileAndDir () {
  local SETUP_CONF_TF="$(checkForFileOrDirectory "$SETUP_CONF_PATH")"
  local SETUP_CONF_DIR_TF="$(checkForFileOrDirectory "$SETUP_CONF_DIR_PATH")"

  printCheckResult 'to see if a "~/.config" directory exists' "$SETUP_CONF_DIR_TF"
  printCheckResult 'to see if a setup config file exists' "$SETUP_CONF_TF"

  if [ "$SETUP_CONF_TF" = true ]; then
    printComment 'The setup config file and directory exist.'
  elif [ "$SETUP_CONF_DIR_TF" = false ]; then
    printComment 'The setup config file and directory do not exist.' 'warning'

    createSetupConfigDirectory
    createSetupConfigFile
  elif [ "$SETUP_CONF_TF" = false ]; then
    printComment 'The setup config file does not exist.' 'warning'

    createSetupConfigFile
  fi

  listDirectories "$SETUP_CONF_DIR_PATH"
}

#-------------------------------------------------------------------------------
# Creates the setup config directory and sets the correct ownership.
#-------------------------------------------------------------------------------
createSetupConfigDirectory () {
  createDirectory "$SETUP_CONF_DIR_PATH"
  setOwner "$SUDO_USER" "$SETUP_CONF_DIR_PATH"
}

#-------------------------------------------------------------------------------
# Creates the setup config file and sets the correct permissions and ownership.
#-------------------------------------------------------------------------------
createSetupConfigFile () {
  createFiles "$SETUP_CONF_PATH"
  setPermissions 600 "$SETUP_CONF_PATH"
  setOwner "$SUDO_USER" "$SETUP_CONF_PATH"
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
# using camelCase. A list of the config keys can be found in the project's
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
  cat "$SETUP_CONF_PATH"
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
  local CONF_OPTION="$(grep "$CONF_KEY" "$SETUP_CONF_PATH")"

  set -f $CONF_OPTION
  
  echo "$2"
}

#-------------------------------------------------------------------------------
# Reloads a variable file that has been added to as part of a script. Takes one
# mandatory argument:
#
# 1. "${1:?}" – the variable file to reload, including directory path and
#    defaulting to "$SETUP_VAR_PATH"
#-------------------------------------------------------------------------------
reloadVarFile () {
	local VAR_FILE_PATH="${1:-"$SETUP_VAR_PATH"}"

	printComment 'Reloading setup variable file at:'
	printComment "$VAR_FILE_PATH"
	
	. "$VAR_FILE_PATH"
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
  local CONF_OPTION_TF="$(checkFileContainsString "$SETUP_CONF_PATH" "$CONF_KEY")"

  printComment "Removing $CONF_KEY from:"
  printComment "$SETUP_CONF_PATH"

  if [ "$CONF_OPTION_TF" = true ]; then  
    sed -i '/^'"$CONF_KEY"'/d' "$SETUP_CONF_PATH"

    printComment "$CONF_KEY removed."
  else
    printComment "$CONF_KEY not found, no changes made." 'warning'
  fi

  listSetupConfig
}

#-------------------------------------------------------------------------------
# Replaces a variable in "./setup/[project-name]-setup.var". Takes three 
# mandatory arguments:
# 
# 1. "${1:?}" – the project's setup variable file name, without "-setup.var" and 
#    excluding the directory path;
# 2. "${2:?}" – the name of the variable to be replaced; and
# 3. "${3:?}" – the new value of the variable.
#
# The function uses "sed" to find the line starting with "$VAR_NAME" and replace
# the entire matched line with "$VAR_NAME="$VAR_VALUE"".
#-------------------------------------------------------------------------------
replaceSetupVar () {
  VAR_FILE_NAME="${1:?}"
  VAR_NAME="${2:?}"
  VAR_VALUE="${3:?}"
  VAR_FILE_PATH="$SETUP_DIR_PATH/$VAR_FILE_NAME-setup.var"

  printComment 'Replacing $'"$VAR_NAME"' in:'
  printComment "$VAR_FILE_PATH"

  sed -i '/^'"$VAR_NAME"'/c\'"$VAR_NAME=\"$VAR_VALUE\"" "$VAR_FILE_PATH"

	if grep "$VAR_NAME" "$VAR_FILE_PATH"; then
		printSeparator
		printComment '$'"$VAR_NAME variable added."
	else
    printComment 'There was a problem replacing the $'"$VAR_NAME variable. Please check the variable file at:" 'error'
    printComment "$VAR_FILE_PATH" 'error'

		exit 1
	fi
	
	reloadVarFile "$VAR_FILE_PATH"
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
  local CONF_OPTION_TF="$(checkFileContainsString "$SETUP_CONF_PATH" "$CONF_KEY")"

  printComment "Writing $CONF_KEY with value $CONF_VALUE to:"
  printComment "$SETUP_CONF_PATH"

  if [ "$CONF_OPTION_TF" = true ]; then
    local EXISTING_CONF_VALUE="$(readSetupConfigValue "$CONF_KEY")"

    printComment "$CONF_KEY already exists with value $EXISTING_CONF_VALUE." 'warning'
  fi

  if [ "$CONF_OPTION_TF" = true ] && [ "$EXISTING_CONF_VALUE" = "$CONF_VALUE" ]; then
    printComment 'No changes made.'
  elif [ "$CONF_OPTION_TF" = true ] && [ "$EXISTING_CONF_VALUE" != "$CONF_VALUE" ]; then
    printComment "Overwriting existing value with $CONF_VALUE." 'warning'

    sed -i '/^'"$CONF_KEY"'/c\'"$CONF_KEY $CONF_VALUE" "$SETUP_CONF_PATH"

    printComment 'Config written.'

    setOwner "$SUDO_USER" "$SETUP_CONF_PATH"
  elif [ "$CONF_OPTION_TF" = false ]; then
    echo "$CONF_KEY $CONF_VALUE" >> "$SETUP_CONF_PATH"

    printComment 'Config written.'

    setOwner "$SUDO_USER" "$SETUP_CONF_PATH"
  else
    printComment 'Something went wrong. Please check your setup config at:' 'error'
    printComment "$SETUP_CONF_PATH." 'error'
    printComment 'You may need to manually add the following to the setup config:' 'error'
    printComment "$CONF_KEY $CONF_VALUE" 'error'

    printScriptExiting true

    exit 1
  fi

  listSetupConfig
}