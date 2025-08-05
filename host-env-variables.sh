#!/bin/sh

#-------------------------------------------------------------------------------
# Functions to check and create host environment variables.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds a "env_keep" statement for a given environment variable. Takes one 
# mandatory argument:
# 
# 1. "${1:?}" -the  name of the environment variable.
# 
# N.B.
# This function assumes that the sudoers config file exists.
#-------------------------------------------------------------------------------
addHostEnvVariableToSudoersConf () {
  local ENV_VARIABLE="${1:?}"
  local ENV_KEEP="Defaults env_keep += \"$ENV_VARIABLE\""

  echo "$ENV_KEEP" >> "$SUDOERS_DEFAULT_CONF"
}

#-------------------------------------------------------------------------------
# Checks for a given environment variable in "$PROFILE". Returns true if the 
# variable is present, returns false if not. Takes one mandatory argument:
# 
# 1. "{1:?}" - the name of the environment variable.
#-------------------------------------------------------------------------------
checkForHostEnvVariable () {
  local ENV_VARIABLE="${1:?}"
  local ENV_TF="$(grep "$ENV_VARIABLE" "$PROFILE")"

  if [ -z "$ENV_TF" ]; then
    echo false
  else
    echo true
  fi
}

#-------------------------------------------------------------------------------
# Checks for, then adds, an environment variable to "$PROFILE". Takes two
# mandatory arguments:
# 
# 1. "{1:?}" - the name of the environment variable; and
# 2. "{2:?}" - the value of the environment variable.
# 
# If the variable is already in "$PROFILE" no changes are made. If the variable
# is not present in "$PROFILE" it is added.
# 
# Variables are added as per:
# 
# - https://askubuntu.com/a/211718
# 
# N.B.
# For the shell to pick this up it requires the user to log out and back in.
#-------------------------------------------------------------------------------
setHostEnvVariable () {
  local ENV_VARIABLE="${1:?}"
  local ENV_VALUE="${2:?}"
  local ENV_TF="$(checkForHostEnvVariable "$ENV_VARIABLE")"
  local EXPORT="export $ENV_VARIABLE=$ENV_VALUE"

  if [ "$ENV_TF" = true ]; then
    printComment "Already added $ENV_VARIABLE. No changes made."
  elif [ "$ENV_TF" = false ]; then
    printComment "Adding $ENV_VARIABLE=$ENV_VALUE to:"
    printComment "$PROFILE"
    echo "$EXPORT" >> "$PROFILE"

    printComment 'Checking value added.'
    printSeparator
    grep "$ENV_VARIABLE" "$PROFILE"
    printSeparator
    printComment "$ENV_VARIABLE added."

    printSeparator
    printComment 'This variable will not be recognised until you log out and back in.'
  fi
}