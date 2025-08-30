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
  local CONF_OPTION_TF="$(checkForSetupConfigOption "$CONF_KEY")"

  printComment 'Checking the setup config to see if this step has already been performed…'
  printComment "Check returned $CONF_OPTION_TF."

  if [ "$CONF_OPTION_TF" = true ]; then
    printComment 'You have already performed this step.' true
    printScriptExiting

    exit 1
  elif [ "$CONF_OPTION_TF" = false ]; then
    printComment 'You have not performed this step. Running script.'
    printSeparator
  else
    printComment 'Something went wrong. Please check your setup config at:' true
    printComment "$SETUP_CONF" true
    printScriptExiting

    exit 1
  fi
}