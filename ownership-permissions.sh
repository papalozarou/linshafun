#!/bin/sh

#-------------------------------------------------------------------------------
# Functions to set ownership and permissions of files and directories.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Sets ownership of a file or directory. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the owner, also used for the group; and
# 2. "${2:?}" – the path of the file or directory.
#-------------------------------------------------------------------------------
setOwner () {
  local USER="${1:?}"
  local GROUP="$USER"
  local FILE_FOLDER="${2:?}"

  printComment "Setting ownership of:"
  printComment "$FILE_FOLDER"
  printComment "to $USER:$GROUP."
  chown -R "$USER:$GROUP" "$FILE_FOLDER"
}

#-------------------------------------------------------------------------------
# Sets permissions of a file or directory. Takes two mandatory arguments:
# 
# 1. "${1:?}" – a user; and
# 2. "${2:?}" – the path of the file or directory.
#-------------------------------------------------------------------------------
setPermissions () {
  local PERMISSIONS="${1:?}"
  local FILE_FOLDER="${2:?}"

  printComment "Setting permissions of:"
  printComment "$FILE_FOLDER"
  printComment "to $PERMISSIONS."
  chmod -R "$PERMISSIONS" "$FILE_FOLDER"
}