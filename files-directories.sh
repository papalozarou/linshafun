#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for checking, creation and deletion of files or directories.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Checks for a file or directory. Returns true of it is present, false if it 
# not. Takes one mandatory argument.
# 
# 1. "{1:?}" - the file or directory to check for.
#-------------------------------------------------------------------------------
checkForFileOrDirectory () {
  local FILE_DIR="${1:?}"

  if [ -f "$FILE_DIR" ] || [ -d "${1:?}" ]; then
    echo true
  else
    echo false
  fi
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
# Removes files or directories. Takes one or more arguements:
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

#-------------------------------------------------------------------------------
# Removes a given postfix from a directory of files. Takes two mandatory 
# arguments:
# 
# 1. "${1:?}" – the directory that contains the file; and
# 2. "${2:?}" – the postfix to remove, defaults to "example".
# 
# "find" is used to capture the files, then spawns a shell to copy and remove 
# the postfix from each file. From:
#
# https://unix.stackexchange.com/a/287554
# 
# As "setup.conf.example" is also copied, we delete it as it's not needed.
#
# N.B.
# "find" can only directly "exec" functions that are known to the global scope, 
# requiring exporting them, which is a bash only feature. Because of this the
# command we want to "exec" is written inline.
#-------------------------------------------------------------------------------
removePostfixFromFiles () {
  local DIR="${1:?}"
  local POSTFIX="${2:-"example"}"

  echoComment "Preparing following service files by removing the $POSTFIX postfix"
  echoComment 'from the filenames:'
  echoSeparator
  find "$DIR" -name "*.$POSTFIX"
  echoSeparator

  echoComment 'Copying files and removing postfixes.'
  echoSeparator
  find "$DIR" -type f -name "*.$POSTFIX" -exec sh -c 'cp -p "$0" "${0%.*}" && echo "Copying $0 to ${0%.*}"' {} \;
  echoSeparator

  rm "$DIR/setup/setup.conf"

  echoComment 'Files copied and postfixes removed.'
}