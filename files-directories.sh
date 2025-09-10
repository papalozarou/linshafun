#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for checking, creation and deletion of files or directories.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Checks to see if a file or directory exists. If the file or directory doesn't 
# exist, or it does exist and the user wants to replace it, (re)create it. Takes 
# four arguments:
# 
# 1. "${1:?}" - the file or directory to check for and create or replace, 
#    including directory path;
# 2. "${2:?}" - the function to execute if the file or directory doesn't exist, 
#    or the user chooses to replace it; 
# 3. "${3:?" - the action being performed, all lowercase, defaulting to 
#    'replace'; and
# 4. "$4" - an optional warning to be displayed if the file is to be replaced or 
#    recreated.
#-------------------------------------------------------------------------------
checkAndCreateOrAskToReplaceFileOrDirectory () {
  local FILE_OR_DIR_PATH="${1:?}"
  local FUNCTION="${2:?}"
  local ACTION="${3:-"recreate"}"
  local WARNING="$4"

  printComment 'Checking for file or directory at:'
  printComment "$FILE_OR_DIR_PATH"

  local FILE_OR_DIR_TF="$(checkForFileOrDirectory "$FILE_OR_DIR_PATH")"

  printComment "The check returned $FILE_OR_DIR_TF."

  if [ "$FILE_OR_DIR_TF" = true ]; then
    promptForUserInput "The file or directory exists. Do you want to $ACTION it (y/n)?" 'This cannot be undone if you answer y/Y.'
    local REPLACE_YN="$(getUserInputYN)"
  elif [ "$FILE_OR_DIR_TF" = false ]; then
    printComment "The file or directory does not exist."
  fi

  if [ "$REPLACE_YN" = true ] || [ "$FILE_OR_DIR_TF" = false ] && [ -n "$WARNING" ]; then
    ("$FUNCTION" "$FILE_OR_DIR_PATH" "$WARNING")
  elif [ "$REPLACE_YN" = true ] || [ "$FILE_OR_DIR_TF" = false ] && [ -z "$WARNING" ]; then
    ("$FUNCTION" "$FILE_OR_DIR_PATH")
  else
    printComment 'No changes were made.'
  fi

  listDirectories "$FILE_OR_DIR_PATH"
}

#-------------------------------------------------------------------------------
# Checks for a file or directory. Returns true of it is present, false if it 
# not. Takes one mandatory argument.
# 
# 1. "{1:?}" - the file or directory to check for, including directory path.
#-------------------------------------------------------------------------------
checkForFileOrDirectory () {
  local FILE_OR_DIR_PATH="${1:?}"

  if [ -f "$FILE_OR_DIR_PATH" ] || [ -d "$FILE_OR_DIR_PATH" ]; then
    echo true
  else
    echo false
  fi
}

#-------------------------------------------------------------------------------
# Copies file(s) and adds a given postfix. Takes two mandatory arguments:
#
# 1. "${1:?}" – the file or files, including directory path; and
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
  local FILE_PATHS="${1:?}"
  local POSTFIX="${2:-".backup"}"

  for FILE_PATH in $FILE_PATHS; do
    printComment "Copying and adding $POSTFIX to the file:"
    printSeparator
    printComment "$FILE_PATH"
    printSeparator

    local FILE_COPY="$(addPostfix "$FILE_PATH" "$POSTFIX")"

    cp -p "$FILE_PATH" "$FILE_COPY"

    printComment 'File copied and postfix added.'
  done
}

#-------------------------------------------------------------------------------
# Copies file(s) and removes a given postfix. Takes two mandatory arguments:
#
# 1. "${1:?}" – the file or files, including directory path; and
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
  local FILE_PATHS="${1:?}"
  local POSTFIX="${2:-".example"}"

  for FILE_PATH in $FILE_PATHS; do
    printComment "Copying and removing $POSTFIX from the file:"
    printSeparator
    printComment "$FILE_PATH"
    printSeparator

    local FILE_COPY="$(removePostfix "$FILE_PATH" "$POSTFIX")"

    cp -p "$FILE_PATH" "$FILE_COPY"

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
# "$DIR_PATH(S)" and "$SUB_DIR_NAME(S)" are not quoted as we explicitly want 
# word splitting here.
# 
# And yes it's a nested loop. What of it?
#-------------------------------------------------------------------------------
createDirectories () {
  local DIR_PATHS="${1:?}"
  local SUB_DIR_NAMES="$2"

  if [ -z "$SUB_DIR_NAMES" ]; then
    for DIR_PATH in $DIR_PATHS; do
      createDirectory "$DIR_PATH"
      listDirectories "$DIR_PATH"
    done
  else
    for DIR_PATH in $DIR_PATHS; do
      PARENT_DIR="$DIR_PATH"
      for SUB_DIR_NAME in $SUB_DIR_NAMES; do
        SUB_DIR_PATH="$PARENT_DIR/$SUB_DIR_NAME"

        createDirectory "$SUB_DIR_PATH"
        listDirectories "$SUB_DIR_PATH"
      done
    done
  fi
}

#-------------------------------------------------------------------------------
# Creates a directory. Takes one mandatory argument:
# 
# 1. "${1:?}" - the directory to create, including directory path.
# 
# Parent directories are created if required.
#-------------------------------------------------------------------------------
createDirectory () {
  local DIR_PATH="${1:?}"
  printComment 'Creating directory at:'
  printComment "$DIR_PATH"
  mkdir -p "$DIR_PATH"
}

#-------------------------------------------------------------------------------
# Creates one or more files. Takes one or more arguments:
# 
# 1. "$@" - one or more files to be created, including directory paths.
# 
# The function loops through each passed argument and creates the file.
#-------------------------------------------------------------------------------
createFiles () {
  for FILE_PATH in "$@"; do
    printComment 'Creating file at:'
    printComment "$FILE_PATH"
    touch "$FILE_PATH"

    printSeparator
    listDirectories "$FILE_PATH"
    printComment 'File created.'
  done
}

#-------------------------------------------------------------------------------
# Gets a list of files with a given prefix. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the prefix to search for, excluding wildcard; and
# 2. "${2:?}" – the directory that contains the files, including the directory 
#    path and defaulting to the users home directory.
# 
# N.B.
# The returned "$FILE_PATHS" variable will:
# 
# - contain directory paths which may require removing; and
# - need iterating over with explicit word splitting, i.e. without quotes in any
#   "for" loop.
#-------------------------------------------------------------------------------
getListOfFilesByPrefix () {
  local PREFIX="${1:?}"
  local DIR_PATH="${2:-"$USER_DIR"}"

  local FILE_PATHS="$(find "$DIR_PATH" -name "$PREFIX*")"

  echo "$FILE_PATHS"
}

#-------------------------------------------------------------------------------
# Gets a list of files with a given postfix. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the postfix to search for, excluding wildcard, defaulting to 
#    ".example"; and
# 2. "${2:?}" – the directory that contains the files, including the directory 
#    path and defaulting to the users home directory.
# 
# N.B.
# The returned "$FILE_PATHS" variable will:
# 
# - contain directory paths which may require removing; and
# - need iterating over with explicit word splitting, i.e. without quotes in any
#   "for" loop.
#-------------------------------------------------------------------------------
getListOfFilesByPostfix () {
  local POSTFIX="${1:-".example"}"
  local DIR_PATH="${2:-"$USER_DIR"}"

  local FILE_PATHS="$(find "$DIR_PATH" -name "*$POSTFIX")"

  echo "$FILE_PATHS"
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
  local DIR_PATHS=${1:?}

  for DIR_PATH in $DIR_PATHS; do
    printComment 'Listing directory:'
    printSeparator
    ls -lna "$DIR_PATH"
    printSeparator
  done
}

#-------------------------------------------------------------------------------
# Removes files or directories. Takes one or more arguments:
# 
# 1. "$@" - one or more files or directories to be removed, including directory 
#    paths.
# 
# The function loops through each passed argument and removes the file or 
# directory.
#-------------------------------------------------------------------------------
removeFileOrDirectory () {
  for FILE_OR_DIR_PATH in "$@"; do
    printComment 'Removing file or directory at:'
    printComment "$FILE_OR_DIR_PATH"
    rm -R "$FILE_OR_DIR_PATH"

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
	local DIR_PATH="${1:-"."}"
	local CURRENT_NAME="${2:?}"
	local NEW_NAME="${3:?}"

	mv "$DIR_PATH/$CURRENT_NAME" "$DIR_PATH/$NEW_NAME"
}