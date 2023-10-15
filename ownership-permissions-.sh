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

  echoComment "Setting ownership of:"
  echoComment "$FILE_FOLDER"
  echoComment "to $USER:$GROUP."
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

  echoComment "Setting permissions of:"
  echoComment "$FILE_FOLDER"
  echoComment "to $PERMISSIONS."
  chmod -R "$PERMISSIONS" "$FILE_FOLDER"
}