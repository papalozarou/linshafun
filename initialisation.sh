#!/bin/sh

# ------------------------------------------------------------------------------
# Functions to help with service initialisation.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Checks and creates all required service files. The function checks for 
# existing service files by grabbing a list of files ending in ".example",
# removing the prefix and checking and creating each file in turn. Takes no
# arguments.
# ------------------------------------------------------------------------------
checkAndCreateServiceFiles () {
  local FILE_PATHS="$(getListOfFilesByPostfix '.example' "$SERVICES_DIR_PATH")"
  local FILE_PATH
  local SERVICE_FILE_PATH

  for FILE_PATH in $FILE_PATHS; do
    SERVICE_FILE_PATH="$(removePostfix "$FILE_PATH" ".example")"

    checkAndCreateOrAskToReplaceFileOrDirectory "$SERVICE_FILE_PATH" 'createServiceFile'
  done
}

# ------------------------------------------------------------------------------
# Creates a service file from its "*.example" file. Takes one mandatory
# argument:
#
# 1. "${1:?}" – the service file, including directory path and excluding the
#    ".example" postfix.
#
# The function first checks if the service file exists, and if so backs it up,
# then creates the new service file from "$1.example".
# ------------------------------------------------------------------------------
createServiceFile () {
  local FILE_PATH="${1:?}"

  if checkForFileOrDirectory "$FILE_PATH"; then
    copyAndAddPostfixToFiles "$FILE_PATH"
  fi

  copyAndRemovePostfixFromFiles "$FILE_PATH.example"
}