#!/bin/sh

#-------------------------------------------------------------------------------
# Functions to help with service initialisation.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Checks and creates all required service files. The function checks for 
# existing service files by grabbing a list of files ending in ".example",
# removing the prefix and checking and creating each file in turn.
# 
# N.B.
# Two global variables are created for the file, both with and without the 
# ".example" postfix, for reuse in the "createServiceFile" function.
#-------------------------------------------------------------------------------
checkAndCreateServiceFiles () {
  local FILES="$(getListOfFilesByPostfix '.example' "$SERVICES_DIR")"

  for FILE in $FILES; do
    if [ "$FILE" != "$SETUP_CONF_EXAMPLE" ]; then
      FILE_W_POSTFIX="$FILE"
      FILE_NO_POSTFIX="$(removePostfix "$FILE" ".example")"

      checkAndCreateOrAskToReplaceFileOrDirectory "$FILE_NO_POSTFIX" 'createServiceFile' 'recreate'
    fi
  done
}

#-------------------------------------------------------------------------------
# Creates services files from "*.example" files.
# 
# The function first checks if a service file exists, and if so backs it up, 
# then creates the new service file from the respective "*.example" file.
# 
# N.B.
# The two global variables, created in "checkAndCreateServiceFiles", are used 
# here to avoid duplicating removing and adding the postfix.
#-------------------------------------------------------------------------------
createServiceFile () {
  local FILE_TF="$(checkForFileOrDirectory "$FILE_NO_POSTFIX")"

  if [ "$FILE_TF" = true ]; then
    copyAndAddPostfixToFiles "$FILE_NO_POSTFIX"
  fi

  copyAndRemovePostfixFromFiles "$FILE_W_POSTFIX"
}