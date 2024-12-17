#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for dealing with ssh keys.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds the newly generated public key to the "authorized_keys" file.
#-------------------------------------------------------------------------------
addKeyToAuthorizedKeys () {
  echoComment "Adding public key to $SSH_DIR/authorized_keys."
  cat "$SSH_KEY.pub" >> "$SSH_DIR/authorized_keys"
  echoComment 'Key added.'
}

#-------------------------------------------------------------------------------
# Generates an ssh key. Takes two arguments:
#
# 1. "${1:?}" – specify a file path; and
# 2. "$2" – an optional email address for the key.
#-------------------------------------------------------------------------------
generateSshKey () {
  local KEY_PATH="${1:?}"
  local KEY_EMAIL="$2"

  echoComment 'Generating an ssh key at:' 
  echoComment "$KEY_PATH."
  echoSeparator

  if [ -z "$KEY_EMAIL" ]; then
    ssh-keygen -t ed25519 -f "$KEY_PATH"
  else
    ssh-keygen -t ed25519 -f "$KEY_PATH" -C "$KEY_EMAIL"
  fi

  echoSeparator
  echoComment 'Key generated.'

  listDirectories "$KEY_PATH"
}