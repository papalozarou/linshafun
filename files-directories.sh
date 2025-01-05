#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for checking, creation and deletion of files or directories.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Checks to see if a file or directory exists. If the file or directory doesn't 
# exist, or it does exist and the user wants to replace it, (re)create it. Takes 
# two mandatory arguments and up to three optional ones:
# 
# 1. "${1:?}" - the file or directory to check for and create or replace;
# 2. "${2:?}" - the function to execute if the file or directory doesn't exist, 
#    or the user chooses to replace it; 
# 3. "${3:?" - the action being performed, all lowercase, defaulting to 
#    'replace'; and
# 3 "$4|5|6" - optional lines to be echoed as "N.B." comments.
#
# If the file is to be replaced or recreated, "shift 3" is used to move variable
# "$4" to variable position "$1", to allow the remaining variables to be 
# passed through to "$FUNCTION" as a group using "$@". As per:
# 
# - https://stackoverflow.com/a/33202350
# - https://unix.stackexchange.com/a/174568
# 
# N.B.
# The "$ACTION" variable is third so 
#-------------------------------------------------------------------------------
checkAndCreateOrAskToReplaceFileOrDirectory () {
  local FILE_OR_DIR="${1:?}"
  local FUNCTION="${2:?}"
  local ACTION="${3:-"recreate"}"
  local NB_LINE_1="$4"
  local NB_LINE_2="$5"
  local NB_LINE_3="$6"

  echoComment 'Checking for file or directory at:'
  echoComment "$FILE_OR_DIR"
  
  local FILE_OR_DIR_TF="$(checkForFileOrDirectory "$FILE_OR_DIR")"

  echoComment "The check returned $FILE_OR_DIR_TF."

  if [ "$FILE_OR_DIR_TF" = true ]; then
    promptForUserInput "The file or directory exists. Do you want to $ACTION it (y/n)?" 'This cannot be undone if you answer y/Y.'
    local REPLACE_YN="$(getUserInputYN)"
  elif [ "$FILE_OR_DIR_TF" = false ]; then
    echoComment "The file or directory does not exist."
  fi
  
  if [ "$REPLACE_YN" = true -o "$FILE_OR_DIR_TF" = false ]; then
    shift 3
  fi

  if [ "$REPLACE_YN" = true -o "$FILE_OR_DIR_TF" = false ] && [ "$#" -ge 1 ]; then
    ("$FUNCTION" "$FILE_OR_DIR" "$@")
  elif [ "$REPLACE_YN" = true -o "$FILE_OR_DIR_TF" = false ] && [ "$#" -eq 0 ]; then
    ("$FUNCTION" "$FILE_OR_DIR")
  else
    echoComment 'No changes were made.'
  fi

  listDirectories "$FILE_OR_DIR"
}

#-------------------------------------------------------------------------------
# Checks for a file or directory. Returns true of it is present, false if it 
# not. Takes one mandatory argument.
# 
# 1. "{1:?}" - the file or directory to check for.
#-------------------------------------------------------------------------------
checkForFileOrDirectory () {
  local FILE_OR_DIR="${1:?}"

  if [ -f "$FILE_OR_DIR" ] || [ -d "$FILE_OR_DIR" ]; then
    echo true
  else
    echo false
  fi
}

#-------------------------------------------------------------------------------
# Copies file(s) and adds a given postfix. Takes two mandatory arguments:
#
# 1. "${1:?}" – the file or files; and
# 2. "${2:?}" – the postfix to add, defaulting to ".backup".
# 
# N.B.
# In the "for" loop, "$FILES" is not quoted as we explicitly want word 
# splitting.
#
# If adding a file extension, the "." must be included at the start of the 
# second argument.
#-------------------------------------------------------------------------------
copyAndAddPostfixToFiles () {
  local FILES="${1:?}"
  local POSTFIX="${2:-".backup"}"

  for FILE in $FILES; do
    echoComment "Copying and adding $POSTFIX to the file:"
    echoSeparator
    echoComment "$FILE"
    echoSeparator

    local FILE_COPY="$(addPostfix "$FILE" "$POSTFIX")"

    cp -p "$FILE" "$FILE_COPY"

    echoComment 'File copied and postfix added.'
  done
}

#-------------------------------------------------------------------------------
# Copies file(s) and removes a given postfix. Takes two mandatory arguments:
#
# 1. "${1:?}" – the file or files; and
# 2. "${2:?}" – the postfix to remove, defaulting to ".example".
# 
# N.B.
# In the "for" loop, "$FILES" is not quoted as we explicitly want word 
# splitting.
#
# If removing a file extension, the "." must be included at the start of the 
# second argument.
#-------------------------------------------------------------------------------
copyAndRemovePostfixFromFiles () {
  local FILES="${1:?}"
  local POSTFIX="${2:-".example"}"

  for FILE in $FILES; do
    echoComment "Copying and removing $POSTFIX from the file:"
    echoSeparator
    echoComment "$FILE"
    echoSeparator

    local FILE_COPY="$(removePostfix "$FILE" "$POSTFIX")"

    cp -p "$FILE" "$FILE_COPY"

    echoComment 'File copied and postfix removed.'
  done
}

#-------------------------------------------------------------------------------
# Creates directories and subdirectories, using "createDirectory". Takes two 
# arguments:
# 
# 1. "${1:?}" - a mandatory single directory path, or multiple directory paths 
#    separated by spaces; and
# 2. "$2" - an optional subdirectory name, or multiple subdirectory names
#    separated by spaces.
#
# All directories, and parent directories if required, are created.
# 
# N.B.
# "$MAIN_DIR" and "$SUB_DIRS" are not quoted as we explicitly want word 
# splitting here.
# 
# And yes it's a nested loop. What of it?
#-------------------------------------------------------------------------------
createDirectories () {
  local MAIN_DIRS="${1:?}"
  local SUB_DIRS="$2"

  if [ -z "$SUB_DIRS" ]; then
    for DIR in $MAIN_DIRS; do
      createDirectory "$DIR"
      listDirectories "$DIR"
    done
  else
    for DIR in $MAIN_DIRS; do
      PARENT_DIR="$DIR"
      for SUB_DIR in $SUB_DIRS; do
        DIR_SUB_DIR="$PARENT_DIR/$SUB_DIR"
        
        createDirectory "$DIR_SUB_DIR"
        listDirectories "$DIR_SUB_DIR"
      done
    done
  fi
}

#-------------------------------------------------------------------------------
# Creates a directory. Takes one mandatory argument:
# 
# 1. "${1:?}" - the directory to create.
# 
# Parent directories are created if required.
#-------------------------------------------------------------------------------
createDirectory () {
  local DIR="${1:?}"
  echoComment 'Creating directory at:'
  echoComment "$DIR"
  mkdir -p "$DIR"
}

#-------------------------------------------------------------------------------
# Creates one or more files. Takes one or more arguments:
# 
# 1. "$@" - one or more files to be created.
# 
# The function loops through each passed argument and creates the file.
#-------------------------------------------------------------------------------
createFiles () {
  for FILE in "$@"; do
    echoComment 'Creating file at:'
    echoComment "$FILE"
    touch "$FILE"

    echoSeparator
    listDirectories "$FILE"
    echoComment 'File created.'
  done
}

#-------------------------------------------------------------------------------
# Gets a list of files with a given prefix. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the prefix to search for, excluding wildcard; and
# 2. "${2:?}" – the directory that contains the files, defaulting to the users 
#    home directory.
# 
# N.B.
# The returned "$FILES" variable will:
# 
# - be returned with directory paths which may require removing; and
# - need iterating over with explicit word splitting, i.e. without quotes in any
#   "for" loop.
#-------------------------------------------------------------------------------
getListOfFilesByPrefix () {
  local PREFIX="${1:?}"
  local DIR="${2:-"$USER_DIR"}"

  local FILES="$(find "$DIR" -name "$PREFIX*")"

  echo "$FILES"
}

#-------------------------------------------------------------------------------
# Gets a list of files with a given postfix. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the postfix to search for, excluding wildcard, defaulting to 
#    ".example"; and
# 2. "${2:?}" – the directory that contains the files, defaulting to the users 
#    home directory.
# 
# N.B.
# The returned "$FILES" variable will:
# 
# - be returned with directory paths which may require removing; and
# - need iterating over with explicit word splitting, i.e. without quotes in any
#   "for" loop.
#-------------------------------------------------------------------------------
getListOfFilesByPostfix () {
  local POSTFIX="${1:-".example"}"
  local DIR="${2:-"$USER_DIR"}"

  local FILES="$(find "$DIR" -name "*$POSTFIX")"

  echo "$FILES"
}

#-------------------------------------------------------------------------------
# Lists one or more directories. Takes one mandatory argument:
# 
# 1. "${1:?}" - a single directory path, or a list of multiple directory paths
#    separated by spaces.
# 
# N.B.
# "$DIR" is not quoted as we explicitly want word splitting here.
#-------------------------------------------------------------------------------
listDirectories () {
  local DIRS=${1:?}

  for DIR in $DIRS; do
    echoComment 'Listing directory:'
    echoSeparator
    ls -lna "$DIR"
    echoSeparator
  done
}

#-------------------------------------------------------------------------------
# Removes files or directories. Takes one or more arguments:
# 
# 1. "$@" - one or more files or directories to be removed.
# 
# The function loops through each passed argument and removes the file or 
# directory.
#-------------------------------------------------------------------------------
removeFileOrDirectory () {
  for FILE_DIR in "$@"; do
    echoComment 'Removing file or directory at:'
    echoComment "$FILE_DIR"
    rm -R $FILE_DIR

    echoComment 'File or directory removed.'
  done    
}