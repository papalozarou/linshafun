#!/bin/sh

# ------------------------------------------------------------------------------
# Functions for checking, setting and reading setup config options.
#
# N.B.
# The setup config file is read from "$SETUP_CONF_PATH". linshafun doesn't set
# it, so the calling project must, e.g. in its own ".var" file.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Adds a variable to a setup variable file. Takes three mandatory arguments:
# 
# 1. "${1:?}" – the setup variable file, including directory path;
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
  local VAR_FILE_PATH="${1:?}"
  local VAR_NAME="${2:?}"
  local VAR_VALUE="${3:?}"
  local STATUS=0

  if ! checkIfValidVariableName "$VAR_NAME"; then
    printComment --error -- "$VAR_NAME is not a valid variable name."

    return 1
  fi

  printComment 'Adding $'"$VAR_NAME variable to:"
  printComment -- "$VAR_FILE_PATH"

  cat <<EOF >> "$VAR_FILE_PATH" || STATUS=1
$VAR_NAME="$VAR_VALUE"
EOF

  printSeparator

  if [ "$STATUS" -ne 0 ] || ! grep "^$VAR_NAME=" "$VAR_FILE_PATH"; then
    printComment --error 'There was a problem adding the $'"$VAR_NAME variable. Please check the variable file at:"
    printComment --error -- "$VAR_FILE_PATH"

    return 1
  fi

  printSeparator
  printComment '$'"$VAR_NAME variable added."

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
#
# Returns 1 if the directory or file can't be created, or if the file's
# permissions or owner can't be set. The called functions print the error.
# ------------------------------------------------------------------------------
checkForAndCreateSetupConfigFileAndDir () {
  local STATUS=0

  printComment 'Checking to see if a "~/.config" directory exists…'
  printComment 'Checking to see if a setup config file exists…'

  if checkForFileOrDirectory "$SETUP_CONF_PATH"; then
    printComment 'The setup config file and directory exist.'
  elif ! checkForFileOrDirectory "$SETUP_CONF_DIR_PATH"; then
    printComment --warning 'The setup config file and directory do not exist.'

    { createDirectory "$SETUP_CONF_DIR_PATH" '' "$SUDO_USER" && createSetupConfigFile; } || STATUS=1
  else
    printComment --warning 'The setup config file does not exist.'

    createSetupConfigFile || STATUS=1
  fi

  if [ "$STATUS" -ne 0 ]; then
    return 1
  fi

  listDirectories "$SETUP_CONF_DIR_PATH"
}

# ------------------------------------------------------------------------------
# Creates the setup config file and sets the correct permissions and ownership.
# Takes no arguments.
#
# Returns 1 if the file can't be created, or if its permissions or owner can't
# be set. The called functions print the error.
# ------------------------------------------------------------------------------
createSetupConfigFile () {
  createFiles "$SETUP_CONF_PATH" || return 1
  setPermissions 600 "$SETUP_CONF_PATH" || return 1
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
  local SERVICE

  if [ -z "${CONF_KEY##configured*}" ]; then
    SERVICE="$(changeCase "${CONF_KEY#'configured'}" 'lower')"

    printf '%s\n' "$SERVICE"
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

  printf '%s\n' "${CONF_OPTION#"$CONF_KEY "}"
}

# ------------------------------------------------------------------------------
# Reloads a variable file that has been added to as part of a script. Takes one
# mandatory argument:
#
# 1. "${1:?}" – the variable file to reload, including directory path.
# ------------------------------------------------------------------------------
reloadVarFile () {
  local VAR_FILE_PATH="${1:?}"

  printComment 'Reloading setup variable file at:'
  printComment -- "$VAR_FILE_PATH"

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
# The "sed" command uses the control character "\001" as its separator.
#
# N.B.
# The config key must be formatted exactly as in the config option file, i.e. 
# using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
# ------------------------------------------------------------------------------
removeSetupConfigOption () {
  local CONF_KEY="${1:?}"
  local SEPARATOR="$(printf '\001')"

  printComment "Removing $CONF_KEY from:"
  printComment -- "$SETUP_CONF_PATH"

  if ! checkFileContainsString "$SETUP_CONF_PATH" "^$CONF_KEY "; then
    printComment --warning -- "$CONF_KEY not found, no changes made."
  elif ! sed -i "\\${SEPARATOR}^${CONF_KEY} ${SEPARATOR}d" "$SETUP_CONF_PATH"; then
    printComment --error "Failed to remove $CONF_KEY from $SETUP_CONF_PATH."

    return 1
  else
    printComment -- "$CONF_KEY removed."
  fi

  listSetupConfig
}

# ------------------------------------------------------------------------------
# Replaces a variable in a setup variable file. Takes three mandatory arguments:
# 
# 1. "${1:?}" – the setup variable file, including directory path;
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
#
# The "sed" commands use the control character "\001" as their separator.
# ------------------------------------------------------------------------------
replaceSetupVar () {
  local VAR_FILE_PATH="${1:?}"
  local VAR_NAME="${2:?}"
  local VAR_VALUE="${3:?}"
  local SEPARATOR="$(printf '\001')"
  local ESCAPED_VALUE="$(printf '%s\n' "$VAR_VALUE" | sed "s${SEPARATOR}\\\\${SEPARATOR}\\\\\\\\${SEPARATOR}g")"

  if ! checkIfValidVariableName "$VAR_NAME"; then
    printComment --error -- "$VAR_NAME is not a valid variable name."

    return 1
  fi

  printComment 'Replacing $'"$VAR_NAME"' in:'
  printComment -- "$VAR_FILE_PATH"

  if ! sed -i "\\${SEPARATOR}^${VAR_NAME}=${SEPARATOR}c\\${VAR_NAME}=\"${ESCAPED_VALUE}\"" "$VAR_FILE_PATH" || ! grep "^$VAR_NAME=" "$VAR_FILE_PATH"; then
    printComment --error 'There was a problem replacing the $'"$VAR_NAME variable. Please check the variable file at:"
    printComment --error -- "$VAR_FILE_PATH"

    return 1
  fi

  printSeparator
  printComment '$'"$VAR_NAME variable replaced."

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
# The "sed" commands use the control character "\001" as their separator.
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
  local STATUS=0
  local SEPARATOR="$(printf '\001')"
  local ESCAPED_VALUE="$(printf '%s\n' "$CONF_VALUE" | sed "s${SEPARATOR}\\\\${SEPARATOR}\\\\\\\\${SEPARATOR}g")"
  local EXISTING_CONF_VALUE

  checkFileContainsString "$SETUP_CONF_PATH" "^$CONF_KEY " || CONF_OPTION_STATUS=1

  printComment "Writing $CONF_KEY with value $CONF_VALUE to:"
  printComment -- "$SETUP_CONF_PATH"

  if [ "$CONF_OPTION_STATUS" -eq 0 ]; then
    EXISTING_CONF_VALUE="$(readSetupConfigValue "$CONF_KEY")"

    printComment --warning -- "$CONF_KEY already exists with value $EXISTING_CONF_VALUE."
  fi

  if [ "$CONF_OPTION_STATUS" -eq 0 ] && [ "$EXISTING_CONF_VALUE" = "$CONF_VALUE" ]; then
    printComment 'No changes made.'
    listSetupConfig

    return 0
  fi

  if [ "$CONF_OPTION_STATUS" -eq 0 ]; then
    printComment --warning "Overwriting existing value with $CONF_VALUE."

    sed -i "\\${SEPARATOR}^${CONF_KEY} ${SEPARATOR}c\\${CONF_KEY} ${ESCAPED_VALUE}" "$SETUP_CONF_PATH" || STATUS=1
  else
    printf '%s\n' "$CONF_KEY $CONF_VALUE" >> "$SETUP_CONF_PATH" || STATUS=1
  fi

  if [ "$STATUS" -ne 0 ]; then
    printComment --error "Failed to write $CONF_KEY to $SETUP_CONF_PATH."

    return 1
  fi

  printComment 'Config written.'

  setOwner "$SUDO_USER" "$SETUP_CONF_PATH"

  listSetupConfig
}