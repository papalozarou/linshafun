#!/bin/sh

#-------------------------------------------------------------------------------
# Functions used by all setup scripts.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Writes the config key and tells the user that the script has finished. Takes 
# one mandatory argument:
# 
# 1. "${1:?}" – the config key to be written.
# 
# N.B.
# The config key must be formatted exactly as in the config option file, i.e. 
# using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
#-------------------------------------------------------------------------------
finaliseScript () {
  local CONF_KEY="${1:?}"

  writeSetupConfigOption "$CONF_KEY" true

  printScriptFinished
}

#-------------------------------------------------------------------------------
# Checks the config file to see if the script has been run and completed before.
# Takes one mandatory argument:
#
# 1. "${1:?}" – the config option key to be used.
#
# If the script has been run before, the script will exit. If not it will run.
# If there is an error, we ask the user to check the setup config file and then
# exit the script.
# 
# N.B.
# The config key must be formatted exactly as in the config option file, i.e. 
# using camelCase. A list of the config keys can be found in 
# "setup.conf.example" in the relevant setup directory.
#-------------------------------------------------------------------------------
initialiseScript () {
  local CONF_KEY="${1:?}"
  local CONF_FILE_TF="$(checkForFileOrDirectory "$SETUP_CONF_PATH")"

  if [ "$CONF_FILE_TF" = false ]; then
    local CONF_OPTION_TF=false
  elif [ "$CONF_FILE_TF" = true ]; then
    local CONF_OPTION_TF="$(checkFileContainsString "$SETUP_CONF_PATH" "$CONF_KEY")"
    
    printCheckResult 'the setup config to see if this step has already been performed' "$CONF_OPTION_TF"
  fi

  if [ "$CONF_OPTION_TF" = true ]; then
    printComment 'You have already performed this step.' 'warning'
    printScriptExiting

    exit 1
  elif [ "$CONF_OPTION_TF" = false ]; then
    printComment 'You have not performed this step. Running script.'
    printSeparator
  else
    printComment 'Something went wrong. Please check your setup config at:' 'error'
    printComment "$SETUP_CONF_PATH" 'error'
    printScriptExiting

    exit 1
  fi
}