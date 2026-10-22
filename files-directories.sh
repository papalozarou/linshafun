#!/bin/sh

# ------------------------------------------------------------------------------
# Functions for checking, creation and deletion of files or directories.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Checks to see if a file or directory exists. If the file or directory doesn't 
# exist, or it does exist and the user wants to replace it, (re)create it. Takes
# four arguments, two of which are mandatory:
# 
# 1. "--replace" – an optional flag, passed first, to ask the user whether to
#    "replace" the file or directory, instead of "recreate" it;
# 2. "${1:?}" – the file or directory to check for and create or replace, 
#    including directory path;
# 3. "${2:?}" – the function to execute if the file or directory doesn't exist, 
#    or the user chooses to replace it; and
# 4. "$3" – an optional warning to be displayed if the file is to be replaced or
#    recreated.
#
# Returns 1 with an error if an option is unknown or comes after the other
# arguments.
#
# "STATUS" stays 0 when the file or directory doesn't exist, so the
# function runs. It is only non-zero when the file or directory exists and the
# user answers n/N.
# ------------------------------------------------------------------------------
checkAndCreateOrAskToReplaceFileOrDirectory () {
  local REPLACE_TF=false
  local OPTION_COUNT=0
  local FILE_OR_DIR_PATH
  local FUNCTION
  local ACTION='recreate'
  local WARNING
  local STATUS=0

  readOptions 'replace=REPLACE_TF' "$@" || return 1
  shift "$OPTION_COUNT"

  FILE_OR_DIR_PATH="${1:?}"
  FUNCTION="${2:?}"
  WARNING="$3"

  if [ "$REPLACE_TF" = true ]; then
    ACTION='replace'
  fi

  printComment 'Checking for file or directory at:'
  printComment -- "$FILE_OR_DIR_PATH"

  if checkForFileOrDirectory "$FILE_OR_DIR_PATH"; then
    promptForUserInput "The file or directory exists. Do you want to $ACTION it (y/n)?" 'This cannot be undone if you answer y/Y.'
    getUserInputYN || STATUS=1
  else
    printComment "The file or directory does not exist."
  fi

  if [ "$STATUS" -ne 0 ]; then
    printComment 'No changes were made.'
  elif [ -n "$WARNING" ]; then
    ("$FUNCTION" "$FILE_OR_DIR_PATH" "$WARNING")
  else
    ("$FUNCTION" "$FILE_OR_DIR_PATH")
  fi

  listDirectories "$FILE_OR_DIR_PATH"
}

# ------------------------------------------------------------------------------
# Checks for a file or directory. Returns 0 if it is present, 1 if it is not.
# Takes one mandatory argument:
# 
# 1. "${1:?}" – the file or directory to check for, including directory path.
# ------------------------------------------------------------------------------
checkForFileOrDirectory () {
  local FILE_OR_DIR_PATH="${1:?}"

  [ -f "$FILE_OR_DIR_PATH" ] || [ -d "$FILE_OR_DIR_PATH" ]
}

# ------------------------------------------------------------------------------
# Copies file(s) and adds a given postfix. Takes two arguments, one of which is
# mandatory:
#
# 1. "${1:?}" – the file or files, including directory path; and
# 2. "${2:-".backup"}" – the postfix to add, defaulting to ".backup".
# 
# N.B.
# In the "for" loop, "$FILES" is not quoted as we explicitly want word 
# splitting.
#
# If adding a file extension, the "." must be included at the start of the 
# second argument.
#
# If a file can't be copied, the function prints an error, carries on with the
# remaining files, and returns 1.
# ------------------------------------------------------------------------------
copyAndAddPostfixToFiles () {
  local FILE_PATHS="${1:?}"
  local POSTFIX="${2:-".backup"}"
  local STATUS=0
  local FILE_PATH
  local FILE_COPY

  for FILE_PATH in $FILE_PATHS; do
    printComment "Copying and adding $POSTFIX to the file:"
    printSeparator
    printComment -- "$FILE_PATH"
    printSeparator

    FILE_COPY="$(addPostfix "$FILE_PATH" "$POSTFIX")"

    if ! cp -p "$FILE_PATH" "$FILE_COPY"; then
      printComment --error "Failed to copy $FILE_PATH to $FILE_COPY."
      STATUS=1

      continue
    fi

    printComment 'File copied and postfix added.'
  done

  return "$STATUS"
}

# ------------------------------------------------------------------------------
# Copies file(s) and removes a given postfix. Takes two arguments, one of
# which is mandatory:
#
# 1. "${1:?}" – the file or files, including directory path; and
# 2. "${2:-".example"}" – the postfix to remove, defaulting to ".example".
# 
# N.B.
# In the "for" loop, "$FILES" is not quoted as we explicitly want word 
# splitting.
#
# If removing a file extension, the "." must be included at the start of the 
# second argument.
#
# If a file can't be copied, the function prints an error, carries on with the
# remaining files, and returns 1.
# ------------------------------------------------------------------------------
copyAndRemovePostfixFromFiles () {
  local FILE_PATHS="${1:?}"
  local POSTFIX="${2:-".example"}"
  local STATUS=0
  local FILE_PATH
  local FILE_COPY

  for FILE_PATH in $FILE_PATHS; do
    printComment "Copying and removing $POSTFIX from the file:"
    printSeparator
    printComment -- "$FILE_PATH"
    printSeparator

    FILE_COPY="$(removePostfix "$FILE_PATH" "$POSTFIX")"

    if ! cp -p "$FILE_PATH" "$FILE_COPY"; then
      printComment --error "Failed to copy $FILE_PATH to $FILE_COPY."
      STATUS=1

      continue
    fi

    printComment 'File copied and postfix removed.'
  done

  return "$STATUS"
}

# ------------------------------------------------------------------------------
# Creates directories and subdirectories, using "createDirectory". Takes two 
# arguments:
# 
# 1. "${1:?}" – a mandatory single directory path, or multiple directory paths 
#    separated by spaces; and
# 2. "$2" – an optional subdirectory name, or multiple subdirectory names
#    separated by spaces.
#
# Each directory path is created before its subdirectories. Directories above
# the given directory paths are not created, as "createDirectory" doesn't create
# missing parent directories.
# 
# N.B.
# "$DIR_PATH(S)" and "$SUB_DIR_NAME(S)" are not quoted as we explicitly want 
# word splitting here.
# 
# And yes it's a nested loop. What of it?
# ------------------------------------------------------------------------------
createDirectories () {
  local DIR_PATHS="${1:?}"
  local SUB_DIR_NAMES="$2"
  local DIR_PATH
  local PARENT_DIR
  local SUB_DIR_NAME
  local SUB_DIR_PATH

  if [ -z "$SUB_DIR_NAMES" ]; then
    for DIR_PATH in $DIR_PATHS; do
      createDirectory "$DIR_PATH"
      listDirectories "$DIR_PATH"
    done
  else
    for DIR_PATH in $DIR_PATHS; do
      PARENT_DIR="$DIR_PATH"
      createDirectory "$PARENT_DIR"

      for SUB_DIR_NAME in $SUB_DIR_NAMES; do
        SUB_DIR_PATH="$PARENT_DIR/$SUB_DIR_NAME"

        createDirectory "$SUB_DIR_PATH"
        listDirectories "$SUB_DIR_PATH"
      done
    done
  fi
}

# ------------------------------------------------------------------------------
# Creates a directory, then sets its permissions and ownership if given. Takes
# four arguments, one of which is mandatory:
#
# 1. "${1:?}" – the directory to create, including directory path;
# 2. "${2:-}" – the permissions in numeric format, e.g. "700", optional;
# 3. "${3:-}" – the owner, optional; and
# 4. "${4:-$3}" – the group, defaulting to the owner.
#
# If the directory already exists, the function returns 0, prints nothing and
# changes nothing, so it can be called on every run. An existing directory with
# a different owner or permissions is left as it is.
#
# If the parent directory doesn't exist, the function prints an error and
# returns 1. If "mkdir", "chmod" or "chown" fails, the function prints an error
# and returns 1.
#
# N.B.
# Missing parent directories are never created, i.e. there is no "mkdir -p",
# so a script run as root can't create a directory owned by root by accident.
# Create each level in order, parent first, or use "createDirectories".
#
# The permissions and owner are set on the new directory only. To set an owner
# without setting permissions, pass "" as the second argument.
#
# The group defaults to the owner name, which only works on systems that
# create a group for each user. Pass the group on systems that do not, e.g.
# "users" on Synology DSM.
# ------------------------------------------------------------------------------
createDirectory () {
  local DIR_PATH="${1:?}"
  local MODE="${2:-}"
  local OWNER="${3:-}"
  local GROUP="${4:-$3}"
  local PARENT_DIR_PATH="$(dirname "$DIR_PATH")"

  if [ -d "$DIR_PATH" ]; then
    return 0
  fi

  if [ ! -d "$PARENT_DIR_PATH" ]; then
    printComment --error "Failed to create the directory at $DIR_PATH, as its parent directory $PARENT_DIR_PATH does not exist."

    return 1
  fi

  printComment 'Creating directory at:'
  printComment -- "$DIR_PATH"

  if ! mkdir "$DIR_PATH"; then
    printComment --error "Failed to create the directory at $DIR_PATH."

    return 1
  fi

  if [ -n "$MODE" ] && ! chmod "$MODE" "$DIR_PATH"; then
    printComment --error "Failed to set permissions of $DIR_PATH to $MODE."

    return 1
  fi

  if [ -n "$OWNER" ] && ! chown "$OWNER:$GROUP" "$DIR_PATH"; then
    printComment --error "Failed to set ownership of $DIR_PATH to $OWNER:$GROUP."

    return 1
  fi
}

# ------------------------------------------------------------------------------
# Creates one or more files. Takes one or more arguments:
# 
# 1. "$@" – one or more files to be created, including directory paths.
# 
# The function loops through each passed argument and creates the file. If a
# file can't be created, the function prints an error, carries on with the
# remaining files, and returns 1.
# ------------------------------------------------------------------------------
createFiles () {
  local STATUS=0
  local FILE_PATH

  for FILE_PATH in "$@"; do
    printComment 'Creating file at:'
    printComment -- "$FILE_PATH"

    if ! touch "$FILE_PATH"; then
      printComment --error "Failed to create the file at $FILE_PATH."
      STATUS=1

      continue
    fi

    printSeparator
    listDirectories "$FILE_PATH"
    printComment 'File created.'
  done

  return "$STATUS"
}

# ------------------------------------------------------------------------------
# Gets a list of files with a given prefix. Takes two arguments, one of which
# is mandatory:
# 
# 1. "${1:?}" – the prefix to search for, excluding wildcard; and
# 2. "${2:-"$USER_DIR_PATH"}" – the directory that contains the files, 
#    including the directory path and defaulting to the users home directory.
# 
# N.B.
# The returned "$FILE_PATHS" variable will:
# 
# - contain directory paths which may require removing; and
# - need iterating over with explicit word splitting, i.e. without quotes in any
#   "for" loop.
# ------------------------------------------------------------------------------
getListOfFilesByPrefix () {
  local PREFIX="${1:?}"
  local DIR_PATH="${2:-"$USER_DIR_PATH"}"

  local FILE_PATHS="$(find "$DIR_PATH" -name "$PREFIX*")"

  echo "$FILE_PATHS"
}

# ------------------------------------------------------------------------------
# Gets a list of files with a given postfix. Takes two arguments:
# 
# 1. "${1:-".example"}" – the postfix to search for, excluding wildcard, 
#    defaulting to ".example"; and
# 2. "${2:-"$USER_DIR_PATH"}" – the directory that contains the files, 
#    including the directory path and defaulting to the users home directory.
# 
# N.B.
# The returned "$FILE_PATHS" variable will:
# 
# - contain directory paths which may require removing; and
# - need iterating over with explicit word splitting, i.e. without quotes in any
#   "for" loop.
# ------------------------------------------------------------------------------
getListOfFilesByPostfix () {
  local POSTFIX="${1:-".example"}"
  local DIR_PATH="${2:-"$USER_DIR_PATH"}"

  local FILE_PATHS="$(find "$DIR_PATH" -name "*$POSTFIX")"

  echo "$FILE_PATHS"
}

# ------------------------------------------------------------------------------
# Lists one or more directories. Takes one mandatory argument:
# 
# 1. "${1:?}" – a single directory path, or a list of multiple directory paths
#    separated by spaces.
# 
# N.B.
# "$DIR" is not quoted as we explicitly want word splitting here.
# ------------------------------------------------------------------------------
listDirectories () {
  local DIR_PATHS=${1:?}
  local DIR_PATH

  for DIR_PATH in $DIR_PATHS; do
    printComment 'Listing directory:'
    printSeparator
    ls -lna "$DIR_PATH"
    printSeparator
  done
}

# ------------------------------------------------------------------------------
# Removes files or directories. Takes one or more arguments:
# 
# 1. "--recursive" – an optional flag, passed first, to also remove directories
#    and everything in them; and
# 2. "$@" – one or more files or directories to be removed, including directory 
#    paths.
# 
# The function loops through each passed argument and removes the file or 
# directory. If a file or directory can't be removed, the function prints an
# error, carries on with the remaining files or directories, and returns 1.
# It also returns 1 with an error, without removing anything, if an option is
# unknown or comes after the paths.
#
# Without "--recursive" only files are removed, matching "rm". A directory is
# left in place and counts as a failure, so a wrong path can't remove a whole
# directory.
#
# N.B.
# "RM_OPTION" is only set when "--recursive" is passed. "${RM_OPTION:+…}"
# passes "-R" when it is set and nothing when it is empty, as a quoted empty
# variable would be passed to "rm" as an empty path, which fails. See "Use
# Alternative Value" in "Parameter Expansion", as per:
#
# - https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html
# ------------------------------------------------------------------------------
removeFilesOrDirectories () {
  local RECURSIVE_TF=false
  local OPTION_COUNT=0
  local RM_OPTION=
  local STATUS=0
  local FILE_OR_DIR_PATH

  readOptions 'recursive=RECURSIVE_TF' "$@" || return 1
  shift "$OPTION_COUNT"

  if [ "$RECURSIVE_TF" = true ]; then
    RM_OPTION='-R'
  fi

  for FILE_OR_DIR_PATH in "$@"; do
    printComment 'Removing file or directory at:'
    printComment -- "$FILE_OR_DIR_PATH"

    if rm ${RM_OPTION:+"$RM_OPTION"} "$FILE_OR_DIR_PATH"; then
      printComment 'File or directory removed.'
    else
      printComment --error 'File or directory could not be removed. Please check it exists and that you have permission to remove it.'
      STATUS=1
    fi
  done

  return "$STATUS"
}

# ------------------------------------------------------------------------------
# Renames a file or directory. Takes two mandatory arguments:
#
# 1. "${1:?}" – the current file or directory, including directory path; and
# 2. "${2:?}" – the new file or directory, including directory path.
#
# If the file or directory can't be renamed, the function prints an error and
# returns 1.
# ------------------------------------------------------------------------------
renameFileOrDirectory () {
  local CURRENT_PATH="${1:?}"
  local NEW_PATH="${2:?}"

  if ! mv "$CURRENT_PATH" "$NEW_PATH"; then
    printComment --error "Failed to rename $CURRENT_PATH to $NEW_PATH."

    return 1
  fi
}