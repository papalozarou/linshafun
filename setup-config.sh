#!/bin/sh

# ------------------------------------------------------------------------------
# Functions for checking, setting and reading setup config options.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Adds a variable to "./setup/[project-name]-setup.var". Takes three mandatory
# arguments:
# 
# 1. "${1:?}" – the project's setup variable file name, without "-setup.var" and 
#    excluding the directory path;
# 2. "${2:?}" – the name of the variable to be added; and
# 3. "${3:?}" – the value of the variable to be added.
#
# If the variable can't be written, or isn't in the file afterwards, the
# function prints an error and returns 1.
#
# If the variable name isn't valid, the function prints an error and returns 1
# without writing anything. The file is sourced, so an invalid name would be
# run as shell code.
#
# Appending to a file using "cat" as per:
# 
# - https://stackoverflow.com/a/50098414
# ------------------------------------------------------------------------------
addSetupVar () {
	local VAR_FILE_NAME="${1:?}"
	local VAR_NAME="${2:?}"
	local VAR_VALUE="${3:?}"
  local VAR_FILE_PATH="$SETUP_DIR_PATH/$VAR_FILE_NAME-setup.var"
  local STATUS=0

  if ! checkIfValidVariableName "$VAR_NAME"; then
    printComment "$VAR_NAME is not a valid variable name." 'error'

    return 1
  fi

	printComment 'Adding $'"$VAR_NAME variable to:"
	printComment "$VAR_FILE_PATH"
	
  cat <<EOF >> "$VAR_FILE_PATH" || STATUS="$?"
$VAR_NAME="$VAR_VALUE"
EOF

	printSeparator
	
	if [ "$STATUS" -eq 0 ] && grep "^$VAR_NAME=" "$VAR_FILE_PATH"; then
		printSeparator
		printComment '$'"$VAR_NAME variable added."
	else
    printComment 'There was a problem adding the $'"$VAR_NAME variable. Please check the variable file at:" 'error'
    printComment "$VAR_FILE_PATH" 'error'

		return 1
	fi
	
	reloadVarFile "$VAR_FILE_PATH"
}

# ------------------------------------------------------------------------------
# Check for a current setup config file and directory. If both exist, do 
# nothing. If either doesn't exist, create them. Takes no arguments. There are
# three possibilities:
# 
# 1. the setup config file exists so the directory must exist;
# 2. the setup config directory doesn't exist so the file can't; or
# 3. the setup config directory exists and the file doesn't.
# ------------------------------------------------------------------------------
checkForAndCreateSetupConfigFileAndDir () {
  printComment 'Checking to see if a "~/.config" directory exists…'
  printComment 'Checking to see if a setup config file exists…'

  if checkForFileOrDirectory "$SETUP_CONF_PATH"; then
    printComment 'The setup config file and directory exist.'
  elif ! checkForFileOrDirectory "$SETUP_CONF_DIR_PATH"; then
    printComment 'The setup config file and directory do not exist.' 'warning'

    createDirectory "$SETUP_CONF_DIR_PATH" '' "$SUDO_USER"
    createSetupConfigFile
  else
    printComment 'The setup config file does not exist.' 'warning'

    createSetupConfigFile
  fi

  listDirectories "$SETUP_CONF_DIR_PATH"
}

# ------------------------------------------------------------------------------
# Creates the setup config file and sets the correct permissions and ownership.
# Takes no arguments.
# ------------------------------------------------------------------------------
createSetupConfigFile () {
  createFiles "$SETUP_CONF_PATH"
  setPermissions 600 "$SETUP_CONF_PATH"
  setOwner "$SUDO_USER" "$SETUP_CONF_PATH"
}

# ------------------------------------------------------------------------------
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
# ------------------------------------------------------------------------------
getServiceFromConfigKey () {
  local CONF_KEY="${1:?}"

  if [ -z "${CONF_KEY##configured*}" ]; then
    local SERVICE="$(changeCase "${CONF_KEY#'configured'}" 'lower')"

    echo "$SERVICE"
  fi
}

# ------------------------------------------------------------------------------
# Lists the contents of the setup config file. Takes no arguments.
# ------------------------------------------------------------------------------
listSetupConfig () {
  printComment 'Listing contents of setup config file:'
  printSeparator
  cat "$SETUP_CONF_PATH"
}

# ------------------------------------------------------------------------------
# Reads and returns a setup config value. Takes one mandatory argument:
# 
# 1. "${1:?}" – the key of the config value.
# 
# "grep" finds the first line starting with the key followed by a space. The key
# and the space are then removed with parameter expansion, leaving the value.
# Values containing spaces are returned whole. If the key isn't found, nothing
# is returned.
#
# N.B.
# The config key must be formatted exactly as in the config option file, i.e. 
# using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
# ------------------------------------------------------------------------------
readSetupConfigValue () {
  local CONF_KEY="${1:?}"
  local CONF_OPTION="$(grep "^$CONF_KEY " "$SETUP_CONF_PATH" | head -n 1)"

  echo "${CONF_OPTION#"$CONF_KEY "}"
}

# ------------------------------------------------------------------------------
# Reloads a variable file that has been added to as part of a script. Takes one
# argument:
#
# 1. "${1:-"$SETUP_VAR_PATH"}" – the variable file to reload, including
#    directory path and defaulting to "$SETUP_VAR_PATH".
# ------------------------------------------------------------------------------
reloadVarFile () {
	local VAR_FILE_PATH="${1:-"$SETUP_VAR_PATH"}"

	printComment 'Reloading setup variable file at:'
	printComment "$VAR_FILE_PATH"
	
	. "$VAR_FILE_PATH"
}

# ------------------------------------------------------------------------------
# Removes a setup config option. Takes one mandatory argument:
# 
# 1. "${1:?}" – the key of the config option.
# 
# If the config option can't be removed, the function prints an error and
# returns 1, without listing the setup config.
#
# N.B.
# The config key must be formatted exactly as in the config option file, i.e. 
# using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
# ------------------------------------------------------------------------------
removeSetupConfigOption () {
  local CONF_KEY="${1:?}"

  printComment "Removing $CONF_KEY from:"
  printComment "$SETUP_CONF_PATH"

  if ! checkFileContainsString "$SETUP_CONF_PATH" "^$CONF_KEY "; then
    printComment "$CONF_KEY not found, no changes made." 'warning'
  elif ! sed -i '/^'"$CONF_KEY"' /d' "$SETUP_CONF_PATH"; then
    printComment "Failed to remove $CONF_KEY from $SETUP_CONF_PATH." 'error'

    return 1
  else
    printComment "$CONF_KEY removed."
  fi

  listSetupConfig
}

# ------------------------------------------------------------------------------
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
#
# If "sed" fails, or the variable isn't in the file afterwards, the function
# prints an error and returns 1. "sed" succeeds even when no line matches, so
# the file is still checked for the variable.
#
# If the variable name isn't valid, the function prints an error and returns 1
# without writing anything. The file is sourced, so an invalid name would be
# run as shell code.
#
# "\" is escaped in the value, as "sed" removes it from the replacement line,
# e.g. "a\b" would be written as "ab".
# ------------------------------------------------------------------------------
replaceSetupVar () {
  VAR_FILE_NAME="${1:?}"
  VAR_NAME="${2:?}"
  VAR_VALUE="${3:?}"
  VAR_FILE_PATH="$SETUP_DIR_PATH/$VAR_FILE_NAME-setup.var"
  local STATUS=0
  local ESCAPED_VALUE="$(printf '%s\n' "$VAR_VALUE" | sed 's/\\/\\\\/g')"

  if ! checkIfValidVariableName "$VAR_NAME"; then
    printComment "$VAR_NAME is not a valid variable name." 'error'

    return 1
  fi

  printComment 'Replacing $'"$VAR_NAME"' in:'
  printComment "$VAR_FILE_PATH"

  sed -i '/^'"$VAR_NAME"'=/c\'"$VAR_NAME=\"$ESCAPED_VALUE\"" "$VAR_FILE_PATH" || STATUS="$?"

	if [ "$STATUS" -eq 0 ] && grep "^$VAR_NAME=" "$VAR_FILE_PATH"; then
		printSeparator
		printComment '$'"$VAR_NAME variable added."
	else
    printComment 'There was a problem replacing the $'"$VAR_NAME variable. Please check the variable file at:" 'error'
    printComment "$VAR_FILE_PATH" 'error'

		return 1
	fi
	
	reloadVarFile "$VAR_FILE_PATH"
}

# ------------------------------------------------------------------------------
# Writes a setup config option. Takes two mandatory arguments:
#
# 1. "${1:?}" – the key of the config option; and
# 2. "${2:?}" – the value of the config option.
#
# Once the config option is written, the file ownership is set to "$SUDO_USER".
# 
# If the config option can't be written, the function prints an error and
# returns 1, without setting the owner or listing the setup config.
#
# "\" is escaped in the value when an existing option is overwritten, as "sed"
# removes it from the replacement line, e.g. "a\b" would be written as "ab".
#
# N.B.
# The config key must be formatted exactly as in the config option file, i.e. 
# using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
# ------------------------------------------------------------------------------
writeSetupConfigOption () {
  local CONF_KEY="${1:?}"
  local CONF_VALUE="${2:?}"
  local CONF_OPTION_STATUS=0
  local WRITE_STATUS=0
  local ESCAPED_VALUE="$(printf '%s\n' "$CONF_VALUE" | sed 's/\\/\\\\/g')"

  checkFileContainsString "$SETUP_CONF_PATH" "^$CONF_KEY " || CONF_OPTION_STATUS="$?"

  printComment "Writing $CONF_KEY with value $CONF_VALUE to:"
  printComment "$SETUP_CONF_PATH"

  if [ "$CONF_OPTION_STATUS" -eq 0 ]; then
    local EXISTING_CONF_VALUE="$(readSetupConfigValue "$CONF_KEY")"

    printComment "$CONF_KEY already exists with value $EXISTING_CONF_VALUE." 'warning'
  fi

  if [ "$CONF_OPTION_STATUS" -eq 0 ] && [ "$EXISTING_CONF_VALUE" = "$CONF_VALUE" ]; then
    printComment 'No changes made.'
    listSetupConfig

    return 0
  fi

  if [ "$CONF_OPTION_STATUS" -eq 0 ]; then
    printComment "Overwriting existing value with $CONF_VALUE." 'warning'

    sed -i '/^'"$CONF_KEY"' /c\'"$CONF_KEY $ESCAPED_VALUE" "$SETUP_CONF_PATH" || WRITE_STATUS=1
  else
    echo "$CONF_KEY $CONF_VALUE" >> "$SETUP_CONF_PATH" || WRITE_STATUS=1
  fi

  if [ "$WRITE_STATUS" -ne 0 ]; then
    printComment "Failed to write $CONF_KEY to $SETUP_CONF_PATH." 'error'

    return 1
  fi

  printComment 'Config written.'

  setOwner "$SUDO_USER" "$SETUP_CONF_PATH"

  listSetupConfig
}