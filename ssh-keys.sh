#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for dealing with ssh keys.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds the newly generated public key to the "authorized_keys" file.
#-------------------------------------------------------------------------------
addKeyToAuthorizedKeys () {
  printComment "Adding public key to $SSH_DIR/authorized_keys."
  cat "$SSH_KEY.pub" >> "$SSH_DIR/authorized_keys"
  printComment 'Key added.'
}

#-------------------------------------------------------------------------------
# Adds a host to "~/.ssh/config". Takes four mandatory arguments:
# 
# 1. "${1:?}" - the name of the host;
# 2. "${2:?}" - the ip address of the host;
# 3. "${3:?}" - the ssh port for the host; and
# 4. "${4:?}" - the user used to login to the host.
#-------------------------------------------------------------------------------
addHostToSshConfig () {
  local HOST="${1:?}"
  local HOSTNAME="${3:?}"
  local PORT="${4:?}"
  local USER="${5:?}"
  local IDENTITY_FILE="$HOST"

cat <<EOF >> "$SSH_CONF"
Host $HOST
	Hostname $HOSTNAME
	Port $PORT
	User $USER
	IdentityFile ~/.ssh/$HOST
EOF

  setPermissions 600 "$SSH_CONF"
}

#-------------------------------------------------------------------------------
# Checks to see if the "~/.ssh/authorized_keys" file exist and creates it if not.
#-------------------------------------------------------------------------------
checkForAndCreateAuthorizedKeys () {
  local SSH_AUTH_KEYS_TF="$(checkForFileOrDirectory "$SSH_AUTH_KEYS")"

  printComment 'Checking for an authorized keys file at:'
  printComment "$SSH_AUTH_KEYS"

  if [ "$SSH_AUTH_KEYS_TF" = true ]; then
    printComment 'The authorized keys file already exists.' true
  elif [ "$SSH_AUTH_KEYS_TF" = false ]; then
    printComment 'Creating an "authorized_keys" file at:'
    printComment "$SSH_AUTH_KEYS"
    createFiles "$SSH_AUTH_KEYS"

    setPermissions 600 "$SSH_AUTH_KEYS"
  fi
}

#-------------------------------------------------------------------------------
# Checks to see if the "~/.ssh" directory exist and creates it if not.
#-------------------------------------------------------------------------------
checkForAndCreateSshDir () {
  local SSH_DIR_TF="$(checkForFileOrDirectory "$SSH_DIR")"

  printComment 'Checking for an "~/.ssh" directory at:'
  printComment "$SSH_DIR"

  if [ "$SSH_DIR_TF" = true ]; then
    printComment 'The "~/.ssh" directory already exists.' true
  elif [ "$SSH_DIR_TF" = false ]; then 
    printComment 'Creating an "~/.ssh" directory at:'
    printComment "$SSH_DIR"
    createDirectory "$SSH_DIR"

    setPermissions 700 "$SSH_DIR"
  fi
}

#-------------------------------------------------------------------------------
# Checks to see if the "~/.ssh/config" file exist and creates it if not, adding
# a basic config to the created file.
#-------------------------------------------------------------------------------
checkForAndCreateSshConfig () {
  local SSH_CONF_TF="$(checkForFileOrDirectory "$SSH_CONF")"

  printComment 'Checking for an ssh config file at:'
  printComment "$SSH_CONF"

  if [ "$SSH_AUTH_KEYS_TF" = true ]; then
    printComment 'The ssh config file already exists.' true
  elif [ "$SSH_CONF_TF" = false ]; then
    printComment 'Creating an ssh config file at:'
    printComment "$SSH_CONF"
    createFiles "$SSH_CONF"

cat <<EOF >> "$SSH_CONF"
Host *
	AddKeysToAgent yes
	IdentitiesOnly yes
	UseKeychain yes
EOF

    setPermissions 600 "$SSH_CONF"
  fi
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

  listDirectories "$KEY_PATH"
}