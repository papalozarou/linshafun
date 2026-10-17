#!/bin/sh

#-------------------------------------------------------------------------------
# Functions to check and create host environment variables.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds an "env_keep" statement for a given environment variable to
# "$SUDOERS_DEFAULT_CONF_PATH", so "sudo" keeps the variable. Takes one
# mandatory argument:
#
# 1. "${1:?}" - the name of the environment variable.
#
# If the statement is already present, no changes are made. If not, its syntax
# is checked with "visudo", it is appended and the file's mode is set to 440.
# The file is created if it doesn't exist.
#
# Returns 1 if the syntax check, the write or "chmod" fails.
#
# N.B.
# "visudo -c -f -" reads the statement from standard input, so only the new
# statement is checked, not the whole file.
#
# - https://www.sudo.ws/docs/man/visudo.man/
#-------------------------------------------------------------------------------
addHostEnvVariableToSudoersConf () {
  local ENV_VAR="${1:?}"
  local ENV_KEEP="Defaults env_keep += \"$ENV_VAR\""

  if grep -Fqx "$ENV_KEEP" "$SUDOERS_DEFAULT_CONF_PATH" 2>/dev/null; then
    printComment "Already added $ENV_VAR. No changes made."

    return 0
  fi

  if ! echo "$ENV_KEEP" | visudo -c -f - > /dev/null; then
    printComment "$ENV_VAR failed the sudoers syntax check." 'error'

    return 1
  fi

  if ! echo "$ENV_KEEP" >> "$SUDOERS_DEFAULT_CONF_PATH" \
    || ! chmod 440 "$SUDOERS_DEFAULT_CONF_PATH"; then
    printComment "Failed to add $ENV_VAR to $SUDOERS_DEFAULT_CONF_PATH." 'error'

    return 1
  fi

  printComment "Added $ENV_VAR to $SUDOERS_DEFAULT_CONF_PATH."
}

#-------------------------------------------------------------------------------
# Checks for a given environment variable in "$PROFILE_PATH". Returns true if 
# the variable is present, returns false if not. Takes one mandatory argument:
# 
# 1. "{1:?}" - the name of the environment variable.
#-------------------------------------------------------------------------------
checkForHostEnvVariable () {
  local ENV_VAR="${1:?}"
  local ENV_TF="$(grep "$ENV_VAR" "$PROFILE_PATH")"

  if [ -z "$ENV_TF" ]; then
    echo false
  else
    echo true
  fi
}

#-------------------------------------------------------------------------------
# Checks for, then adds, an environment variable to "$PROFILE_PATH". Takes two
# mandatory arguments:
# 
# 1. "{1:?}" - the name of the environment variable; and
# 2. "{2:?}" - the value of the environment variable.
# 
# If the variable is already in "$PROFILE_PATH" no changes are made. If the 
# variable is not present in "$PROFILE_PATH" it is added.
# 
# Variables are added as per:
# 
# - https://askubuntu.com/a/211718
# 
# N.B.
# For the shell to pick this up it requires the user to log out and back in.
#-------------------------------------------------------------------------------
setHostEnvVariable () {
  local ENV_VAR="${1:?}"
  local ENV_VALUE="${2:?}"
  local ENV_TF="$(checkForHostEnvVariable "$ENV_VAR")"
  local EXPORT="export $ENV_VAR=$ENV_VALUE"

  if [ "$ENV_TF" = true ]; then
    printComment "Already added $ENV_VAR. No changes made."
  elif [ "$ENV_TF" = false ]; then
    printComment "Adding $ENV_VAR=$ENV_VALUE to:"
    printComment "$PROFILE_PATH"
    echo "$EXPORT" >> "$PROFILE_PATH"

    printComment 'Checking value added…'
    printSeparator
    grep "$ENV_VAR" "$PROFILE_PATH"
    printSeparator
    printComment "$ENV_VAR added."

    printSeparator
    printComment 'This variable will not be recognised until you log out and back in.' 'warning'
  fi
}