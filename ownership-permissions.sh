#!/bin/sh

#-------------------------------------------------------------------------------
# Functions to set ownership and permissions of files and directories.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Sets ownership of a file or directory. Takes three arguments, two of which
# are mandatory:
#
# 1. "${1:?}" – the owner;
# 2. "${2:?}" – the path of the file or directory; and
# 3. "${3:-$1}" – the group, defaulting to the owner.
#
# N.B.
# The group defaults to the owner name, which only works on systems that
# create a group for each user. Pass the group on systems that do not, i.e.
# "users" on Synology DSM.
#-------------------------------------------------------------------------------
setOwner () {
  local USER="${1:?}"
  local FILE_DIR_PATH="${2:?}"
  local GROUP="${3:-$USER}"

  printComment "Setting ownership of:"
  printComment "$FILE_DIR_PATH"
  printComment "to $USER:$GROUP."
  chown -R "$USER:$GROUP" "$FILE_DIR_PATH"
}

#-------------------------------------------------------------------------------
# Sets permissions of a file or directory. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the permissions in numeric format, i.e. "600"; and
# 2. "${2:?}" – the path of the file or directory.
#-------------------------------------------------------------------------------
setPermissions () {
  local PERMISSIONS="${1:?}"
  local FILE_DIR_PATH="${2:?}"

  printComment "Setting permissions of:"
  printComment "$FILE_DIR_PATH"
  printComment "to $PERMISSIONS."
  chmod -R "$PERMISSIONS" "$FILE_DIR_PATH"
}