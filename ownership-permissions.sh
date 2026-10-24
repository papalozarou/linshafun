#!/bin/sh

# ------------------------------------------------------------------------------
# Functions to set ownership and permissions of files and directories.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Sets ownership of a file or directory. Takes four arguments, two of which
# are mandatory:
#
# 1. "--recursive" – an optional flag, passed first, to also set ownership of
#    every directory and file inside the directory;
# 2. "${1:?}" – the owner;
# 3. "${2:?}" – the path of the file or directory; and
# 4. "${3:-$1}" – the group, defaulting to the owner.
#
# Without "--recursive" only the given path is changed, matching "chown".
#
# If the ownership can't be set, the function prints an error and returns 1.
# It also returns 1 with an error if an option is unknown or comes after the
# other arguments.
#
# N.B.
# The group defaults to the owner name, which only works on systems that
# create a group for each user. Pass the group on systems that do not, e.g.
# "users" on Synology DSM.
#
# "$CHOWN_OPTION" is not quoted in the "chown" command as we explicitly want
# word splitting here. Without "--recursive" it is empty, so no empty argument
# is passed to "chown".
# ------------------------------------------------------------------------------
setOwner () {
  local RECURSIVE_TF=false
  local OPTION_COUNT=0
  local OWNER
  local FILE_DIR_PATH
  local GROUP
  local CHOWN_OPTION=

  readOptions 'recursive=RECURSIVE_TF' "$@" || return 1
  shift "$OPTION_COUNT"

  OWNER="${1:?}"
  FILE_DIR_PATH="${2:?}"
  GROUP="${3:-$OWNER}"

  if [ "$RECURSIVE_TF" = true ]; then
    CHOWN_OPTION='-R'
  fi

  printComment "Setting ownership of:"
  printComment -- "$FILE_DIR_PATH"
  printComment "to $OWNER:$GROUP."

  if ! chown $CHOWN_OPTION "$OWNER:$GROUP" "$FILE_DIR_PATH"; then
    printComment --error "Failed to set ownership of $FILE_DIR_PATH to $OWNER:$GROUP."

    return 1
  fi
}

# ------------------------------------------------------------------------------
# Sets permissions of a file or directory. Takes four arguments, two of which
# are mandatory:
# 
# 1. "--recursive" – an optional flag, passed first, to also set permissions of
#    every directory and file inside the directory;
# 2. "${1:?}" – the permissions in numeric format, e.g. "600", or with
#    "--recursive", the permissions of the directory and every directory inside
#    it, e.g. "700";
# 3. "${2:?}" – the path of the file or directory; and
# 4. "${3:?}" – with "--recursive" only, the permissions of every file inside
#    the directory, e.g. "600".
#
# Without "--recursive" only the given path is changed, matching "chmod".
#
# If the permissions can't be set, the function prints an error and returns 1.
# It also returns 1 with an error if an option is unknown or comes after the
# other arguments. The shell stops the script if "--recursive" is passed
# without the permissions of the files.
#
# N.B.
# "chmod -R" would give files the same permissions as directories, so "find"
# changes directories and files separately. "-H" follows the path if it is a
# symbolic link, but not symbolic links inside it. Anything inside that is not
# a directory or a file, e.g. a symbolic link or socket, is left as it is.
# ------------------------------------------------------------------------------
setPermissions () {
  local RECURSIVE_TF=false
  local OPTION_COUNT=0
  local PERMISSIONS
  local FILE_DIR_PATH
  local FILE_PERMISSIONS=

  readOptions 'recursive=RECURSIVE_TF' "$@" || return 1
  shift "$OPTION_COUNT"

  PERMISSIONS="${1:?}"
  FILE_DIR_PATH="${2:?}"

  if [ "$RECURSIVE_TF" = true ]; then
    FILE_PERMISSIONS="${3:?}"
  fi

  printComment "Setting permissions of:"
  printComment -- "$FILE_DIR_PATH"
  printComment "to $PERMISSIONS."

  if [ "$RECURSIVE_TF" = true ]; then
    printComment "Directories inside are set to $PERMISSIONS and files to $FILE_PERMISSIONS."
  fi

  if [ "$RECURSIVE_TF" = false ] && ! chmod "$PERMISSIONS" "$FILE_DIR_PATH"; then
    printComment --error "Failed to set permissions of $FILE_DIR_PATH to $PERMISSIONS."

    return 1
  fi

  if [ "$RECURSIVE_TF" = true ] && ! find -H "$FILE_DIR_PATH" -type d -exec chmod "$PERMISSIONS" {} +; then
    printComment --error "Failed to set permissions of directories in $FILE_DIR_PATH to $PERMISSIONS."

    return 1
  fi

  if [ "$RECURSIVE_TF" = true ] && ! find -H "$FILE_DIR_PATH" -type f -exec chmod "$FILE_PERMISSIONS" {} +; then
    printComment --error "Failed to set permissions of files in $FILE_DIR_PATH to $FILE_PERMISSIONS."

    return 1
  fi
}