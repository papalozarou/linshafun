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
# 3 "$4" - optional warning to be displayed.
#
# If the file is to be replaced or recreated, "shift 3" is used to move variable
# "$4" to variable position "$1", to allow the warning to be passed through to 
# "$FUNCTION". As per:
# 
# - https://stackoverflow.com/a/33202350
# - https://unix.stackexchange.com/a/174568
#-------------------------------------------------------------------------------
checkAndCreateOrAskToReplaceFileOrDirectory () {
  local FILE_OR_DIR="${1:?}"
  local FUNCTION="${2:?}"
  local ACTION="${3:-"recreate"}"
  local WARNING="$4"

  printComment 'Checking for file or directory at:'
  printComment "$FILE_OR_DIR"
  
  local FILE_OR_DIR_TF="$(checkForFileOrDirectory "$FILE_OR_DIR")"

  printComment "The check returned $FILE_OR_DIR_TF."

  if [ "$FILE_OR_DIR_TF" = true ]; then
    promptForUserInput "The file or directory exists. Do you want to $ACTION it (y/n)?" 'This cannot be undone if you answer y/Y.'
    local REPLACE_YN="$(getUserInputYN)"
  elif [ "$FILE_OR_DIR_TF" = false ]; then
    printComment "The file or directory does not exist."
  fi
  
  if [ "$REPLACE_YN" = true -o "$FILE_OR_DIR_TF" = false ]; then
    shift 3
  fi

  if [ "$REPLACE_YN" = true -o "$FILE_OR_DIR_TF" = false ] && [ "$#" -ge 1 ]; then
    ("$FUNCTION" "$FILE_OR_DIR" "$1")
  elif [ "$REPLACE_YN" = true -o "$FILE_OR_DIR_TF" = false ] && [ "$#" -eq 0 ]; then
    ("$FUNCTION" "$FILE_OR_DIR")
  else
    printComment 'No changes were made.'
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
    printComment "Copying and adding $POSTFIX to the file:"
    printSeparator
    printComment "$FILE"
    printSeparator

    local FILE_COPY="$(addPostfix "$FILE" "$POSTFIX")"

    cp -p "$FILE" "$FILE_COPY"

    printComment 'File copied and postfix added.'
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
    printComment "Copying and removing $POSTFIX from the file:"
    printSeparator
    printComment "$FILE"
    printSeparator

    local FILE_COPY="$(removePostfix "$FILE" "$POSTFIX")"

    cp -p "$FILE" "$FILE_COPY"

    printComment 'File copied and postfix removed.'
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
  printComment 'Creating directory at:'
  printComment "$DIR"
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
    printComment 'Creating file at:'
    printComment "$FILE"
    touch "$FILE"

    printSeparator
    listDirectories "$FILE"
    printComment 'File created.'
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
    printComment 'Listing directory:'
    printSeparator
    ls -lna "$DIR"
    printSeparator
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
    printComment 'Removing file or directory at:'
    printComment "$FILE_DIR"
    rm -R $FILE_DIR

    printComment 'File or directory removed.'
  done    
}

#-------------------------------------------------------------------------------
# Renames a file or directory. Takes three arguments, two of which are mandatory:
#
# 1. "${1:?}" - the directory path to the file or directory, defaulting to the
#    current directory, ".";
# 2. "${2:?}" - the current file or directory name; and
# 3. "${3:?}" - the new file or directory name.
#-------------------------------------------------------------------------------
renameFileOrDirectory () {
	local DIR="${1:-"."}"
	local CURRENT_NAME="${2:?}"
	local NEW_NAME="${3:?}"
	
	mv "$DIR/$CURRENT_NAME" "$DIR/$NEW_NAME"
}