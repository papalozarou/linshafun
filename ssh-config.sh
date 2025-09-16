#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for dealing with ssh keys.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds a host to "~/.ssh/config". Takes four arguments:
# 
# 1. "${1:?}" - the name of the host;
# 2. "$2" - the address of the host, either an IP address or a hostname;
# 3. "$3" - the ssh port for the host; and
# 4. "$4" - the user used to login to the host.
#
# The function tests the three non-mandatory arguments to see if they are set,
# and if so adds them to the host config.
#
# N.B.
# Although these variables may exist in the global scope if "getSshHostDetails" 
# has been used, this allows fixed details to be passed in if required.
#-------------------------------------------------------------------------------
addHostToSshConfig () {
  local HOST="${1:?}"
  local HOSTNAME="$2"
  local PORT="$3"
  local USER="$4"
  local IDENTITY_FILE_NAME="$HOST"

  printComment "Adding host, $HOST, to ssh config file at:"
  printComment "$SSH_CONF"

  {
    echo "Host $HOST"
    [ -n "$HOSTNAME" ] && echo "  Hostname $HOSTNAME"
    [ -n "$PORT" ] && echo "  Port $PORT"
    [ -n "$USER" ] && echo "  User $USER"
    [ -n "$IDENTITY_FILE_NAME" ] && echo "  IdentityFile ~/.ssh/$IDENTITY_FILE_NAME"
    echo
  } >> "$SSH_CONF"

  setPermissions 600 "$SSH_CONF"
  setOwner "$SUDO_USER" "$SSH_CONF"
}

#-------------------------------------------------------------------------------
# Checks to see if the "~/.ssh" directory exist and creates it if not.
#-------------------------------------------------------------------------------
checkForAndCreateSshDir () {
  local SSH_DIR_TF="$(checkForFileOrDirectory "$SSH_DIR_PATH")"

  printComment 'Checking for an "~/.ssh" directory.'
  printComment "Check returned $SSH_DIR_TF."

  if [ "$SSH_DIR_TF" = true ]; then
    printComment 'The "~/.ssh" directory already exists.' 'warning'
  elif [ "$SSH_DIR_TF" = false ]; then
    printComment 'Creating an "~/.ssh" directory at:'
    printComment "$SSH_DIR_PATH"
    createDirectory "$SSH_DIR_PATH"

    setPermissions 700 "$SSH_DIR_PATH"
    setOwner "$SUDO_USER" "$SSH_DIR_PATH"
  fi
}

#-------------------------------------------------------------------------------
# Checks to see if the "~/.ssh/config" file exist and creates it if not, adding
# a basic config to the created file.
#-------------------------------------------------------------------------------
checkForAndCreateSshConfig () {
  local SSH_CONF_TF="$(checkForFileOrDirectory "$SSH_CONF_PATH")"

  printComment 'Checking for an ssh config file.'
  printComment "Check returned $SSH_CONF_TF."

  if [ "$SSH_CONF_TF" = true ]; then
    printComment 'The ssh config file already exists.' 'warning'
  elif [ "$SSH_CONF_TF" = false ]; then
    printComment 'Creating an ssh config file at:'
    printComment "$SSH_CONF_PATH"
    createFiles "$SSH_CONF_PATH"

    cat <<EOF > "$SSH_CONF_PATH"
Host *
  AddKeysToAgent yes
  IdentitiesOnly yes
  
EOF

    setPermissions 600 "$SSH_CONF_PATH"
    setOwner "$SUDO_USER" "$SSH_CONF_PATH"
  fi
}

#-------------------------------------------------------------------------------
# Gets details of an SSH host for adding to the ssh config file. Details are 
# stored in global variables to allow other functions to use them.
#-------------------------------------------------------------------------------
getSshHostDetails () {
  promptForUserInput 'What is the name of the host you want to add?'
  SSH_HOST="$(getUserInput)"

  promptForUserInput 'What is the ip address of the host you want to add?'
  SSH_HOSTNAME="$(getUserInput)"  

  promptForUserInput 'What is the ssh port for the host you want to add?'
  SSH_PORT="$(getUserInput)"

  promptForUserInput 'What is the name of the ssh user for the host you want to add?'
  SSH_USER="$(getUserInput)"  
}

#-------------------------------------------------------------------------------
# Displays the values a user needs to add to their local ssh config file. Takes
# one mandatory argument:
# 
# 1. "${1:?}" - the ssh port number.
#-------------------------------------------------------------------------------
printLocalSshConfig () {
  local SSH_PORT=${1:?}
  local IP_ADDRESS="$(readIpAddress)"
  local SSH_KEY_FILE_NAME="$(readSetupConfigValue "sshKeyFile")"

  printComment 'To enable easy connection from your local machine, add the following to your local ssh config file at either:'
  printComment '~/.ssh/ssh_config'
  printComment '~/.ssh/config'
  printSeparator
  printComment "Host $SSH_KEY_FILE_NAME"
  printComment "  Hostname $IP_ADDRESS"
  printComment "  Port $SSH_PORT"
  printComment "  User $SUDO_USER"
  printComment "  IdentityFile ~/.ssh/$SSH_KEY_FILE_NAME"
  printSeparator
}