#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for dealing with ssh keys.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Start the "ssh-agent" and add the newly generated key to it.
#-------------------------------------------------------------------------------
addSshKeytoAgent () {
  printComment 'Adding the generated key to the ssh-agent.'
  printSeparator
  eval "$(ssh-agent -s)"
  ssh-add "$SSH_KEY_PATH"
  printSeparator
  printComment 'Key added to agent.'
}

#-------------------------------------------------------------------------------
# Adds the newly generated public key to the "authorized_keys" file.
#-------------------------------------------------------------------------------
addKeyToAuthorizedKeys () {
  printComment 'Adding public key to:'
  printComment "$SSH_AUTH_KEYS_PATH"
  cat "$SSH_KEY_PATH.pub" >> "$SSH_AUTH_KEYS_PATH"
  printComment 'Key added.'
}

#-------------------------------------------------------------------------------
# Checks to see if the "~/.ssh/authorized_keys" file exist and creates it if not.
#-------------------------------------------------------------------------------
checkForAndCreateAuthorizedKeys () {
  local SSH_AUTH_KEYS_TF="$(checkForFileOrDirectory "$SSH_AUTH_KEYS_PATH")"

  printComment 'Checking for an authorized keys file.'
  printComment "Check returned $SSH_AUTH_KEYS_TF."

  if [ "$SSH_AUTH_KEYS_TF" = true ]; then
    printComment 'The authorized keys file already exists.' 'warning'
  elif [ "$SSH_AUTH_KEYS_TF" = false ]; then
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
# If yes, removes the key, if no or other input the function directs the user to
# copy the key and runs this function again.
#-------------------------------------------------------------------------------
checkPrivateSshKeyCopied () {
  local KEY_PATH="${1:?}"

  promptForUserInput "Have you copied the private key to your local ssh directory (y/n)?" 'If you answer y and have not copied the key, you will lose access via ssh.'
  KEY_COPIED_YN="$(getUserInputYN)"

  if [ "$KEY_COPIED_YN" = true ]; then
    removePrivateSshKey "$KEY_PATH"
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
  local KEY_COPIED_YN="$(getUserInputYN)"

  if [ "$KEY_COPIED_YN" != true ]; then
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
#-------------------------------------------------------------------------------
generateSshKey () {
  local KEY_PATH="${1:?}"
  local KEY_EMAIL="$2"

  printComment 'Generating an ssh key at:' 
  printComment "$KEY_PATH."
  printSeparator

  if [ -z "$KEY_EMAIL" ]; then
    ssh-keygen -t ed25519 -f "$KEY_PATH"
  else
    ssh-keygen -t ed25519 -f "$KEY_PATH" -C "$KEY_EMAIL"
  fi

  printSeparator
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

#-------------------------------------------------------------------------------
# Removes a private key. Takes one mandatory argument:
# 
# 1. "${1:?}" - the ssh key file, including directory path.
#-------------------------------------------------------------------------------
removePrivateSshKey () {
  local KEY_PATH="${1:?}"

  printComment 'Removing the private key at:'
  printComment "$KEY_PATH"
  rm "$KEY_PATH"
  printComment "Private key removed."
}

#-------------------------------------------------------------------------------
# Removes a public key. Takes one mandatory argument:
# 
# 1. "${1:?}" - the ssh key file, including directory path.
#-------------------------------------------------------------------------------
removePublicSshKey () {
  local KEY_PATH="${1:?}"

  printComment 'Removing the public key at:'
  printComment "$KEY_PATH"
  rm "$KEY_PATH.pub"
  printComment "Public key removed."
}