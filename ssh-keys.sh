#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for dealing with ssh keys.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds a public key to the "authorized_keys" file. Takes one mandatory argument:
# 
# 1. "${1:?}" – the key file, including directory path.
# 
# If the public key can't be read or added, the function prints an error and
# returns 1.
#
# N.B.
# "authorized_keys" is created by the redirect even when the public key can't
# be read.
#-------------------------------------------------------------------------------
addKeyToAuthorizedKeys () {
  local KEY_PATH="${1:?}.pub"

  printComment 'Adding public key to:'
  printComment "$SSH_AUTH_KEYS_PATH"

  if ! cat "$KEY_PATH" >> "$SSH_AUTH_KEYS_PATH"; then
    printComment "Failed to add the public key at $KEY_PATH." 'error'

    return 1
  fi

  printComment 'Key added.'
}

#-------------------------------------------------------------------------------
# Checks to see if the "~/.ssh/authorized_keys" file exist and creates it if not.
#-------------------------------------------------------------------------------
checkForAndCreateAuthorizedKeys () {
  printComment 'Checking to see if an "~/.ssh/authorized_keys" file exists…'

  if checkForFileOrDirectory "$SSH_AUTH_KEYS_PATH"; then
    printComment 'The authorized keys file already exists.' 'warning'
  else
    printComment 'Creating an authorized_keys file at:'
    printComment "$SSH_AUTH_KEYS_PATH"
    createFiles "$SSH_AUTH_KEYS_PATH"

    setPermissions 600 "$SSH_AUTH_KEYS_PATH"
    setOwner "$SUDO_USER" "$SSH_AUTH_KEYS_PATH"
  fi
}

#-------------------------------------------------------------------------------
# Checks that a user has copied a private key. Takes one mandatory argument:
# 
# 1. "${1:?}" – the key file, including directory path.
# 
# If "yes", removes the key, if "no' or other input the function directs the 
# user to copy the key and runs this function again.
#-------------------------------------------------------------------------------
checkPrivateSshKeyCopied () {
  local KEY_PATH="${1:?}"

  promptForUserInput "Have you copied the private key to your local ssh directory (y/n)?" 'If you answer y and have not copied the key, you will lose access via ssh.'

  if getUserInputYN; then
    removeFileOrDirectory "$KEY_PATH"
  else
    printComment 'You must copy the private key below to your local ssh directory.' 'error'
    printComment "$KEY_PATH" 'error'

    checkPrivateSshKeyCopied "$KEY_PATH"
  fi
}

#-------------------------------------------------------------------------------
# Checks that a user has copied a public key to a remote servers 
# "~/.ssh/authorized_keys" file. Takes one mandatory argument:
# 
# 1. "${1:?}" – the key file, including directory path.
# 
# If no or other input the function directs the user to copy the key and runs 
# this function again.
#-------------------------------------------------------------------------------
checkPublicSshKeyCopied () {
  local KEY_PATH="${1:?}"

  promptForUserInput "Have you copied the public key to your remote server's authorized_keys file (y/n)?" 'If you answer y and have not copied the key, you will lose access via ssh.'

  if ! getUserInputYN; then
    printComment "You must copy the public key below to your remote server's authorized_keys file." 'error'
    printComment "$KEY_PATH" 'error'

    checkPublicSshKeyCopied "$KEY_PATH"
  fi
}

#-------------------------------------------------------------------------------
# Generates an ssh key. Takes two arguments:
#
# 1. "${1:?}" – the key file, including directory path; and
# 2. "$2" – an optional email address for the key.
#
# If "ssh-keygen" fails, the function prints an error and returns 1, without
# setting the permissions or owner of the key files.
#
# N.B.
# "ssh-keygen" asks before overwriting an existing key, and exits with 1 if the
# answer is "n".
#-------------------------------------------------------------------------------
generateSshKey () {
  local KEY_PATH="${1:?}"
  local KEY_EMAIL="$2"
  local STATUS=0

  printComment 'Generating an ssh key at:' 
  printComment "$KEY_PATH."
  printSeparator

  if [ -z "$KEY_EMAIL" ]; then
    ssh-keygen -t ed25519 -f "$KEY_PATH" || STATUS="$?"
  else
    ssh-keygen -t ed25519 -f "$KEY_PATH" -C "$KEY_EMAIL" || STATUS="$?"
  fi

  printSeparator

  if [ "$STATUS" -ne 0 ]; then
    printComment "Failed to generate an ssh key at $KEY_PATH." 'error'

    return 1
  fi

  printComment 'Key generated.'
  setPermissions 600 "$KEY_PATH"
  setOwner "$SUDO_USER" "$KEY_PATH"
  setPermissions 600 "$KEY_PATH.pub"
  setOwner "$SUDO_USER" "$KEY_PATH.pub"

  listDirectories "$KEY_PATH"
}

#-------------------------------------------------------------------------------
# Get the name of the ssh key and the ssh email if desired. Both variables are 
# stored in global variables to allow other functions to use them
#-------------------------------------------------------------------------------
getSshKeyDetails () {
  promptForUserInput 'What do you want to call your ssh key?'
  SSH_KEY_NAME="$(getUserInput)"

  promptForUserInput 'What email do you want to add to your ssh key?'
  SSH_EMAIL="$(getUserInput)"

  SSH_KEY_PATH="$SSH_DIR_PATH/$SSH_KEY_NAME"
}

#-------------------------------------------------------------------------------
# Tell the user to copy the private key to their local machine. Takes one 
# mandatory argument:
#
# 1. "${1:?}" - the name of the ssh key file, excluding directory path.
#-------------------------------------------------------------------------------
printPrivateKeyUsage () {
  local KEY_NAME="${1:?}"

  printComment "Please copy the private key, $KEY_NAME, to your local "'"~/.ssh" directory.'
}

#-------------------------------------------------------------------------------
# Tell the user to copy the private key to their local machine. Takes one 
# mandatory argument:
# 
# 1. "${1:?}" - the name of the ssh key file, excluding directory path.
#-------------------------------------------------------------------------------
printPublicKeyUsage () {
  local KEY_NAME="${1:?}"

  printComment "Please copy the public key, $KEY_NAME, to your remote ssh host's "'"~/.ssh/authorized_keys" file.'
}