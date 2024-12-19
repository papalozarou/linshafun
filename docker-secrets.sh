#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for manipulating docker secrets
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Creates "$DOCKER_SECRETS_DIR", first checking to see if it already exists. If
# it exists, do nothing. If it doesn't create it.
#-------------------------------------------------------------------------------
createDockerSecretsDir () {
  local DOCKER_SECRETS_DIR_TF="$(checkForFileOrDirectory "SDOCKER_SERCRETS_DIR")"

  echoComment 'Checking for a docker secrets directory at:'
  echoComment "$DOCKER_SECRETS_DIR"

  if [ "$DOCKER_SECRETS_DIR_TF" = true ]; then
    echoComment 'The docker secrets dir already exists.'
  elif [ "$DOCKER_SECRETS_DIR_TF" = false ]; then
    createDirectory "$DOCKER_SECRETS_DIR"
    setPermissions '600' "$DOCKER_SECRETS_DIR"
  fi
}

#-------------------------------------------------------------------------------
# Generates secrets, using a random string. Takes at least one mandatory 
# argument:
# 
# 1. "$@" - the name(s) of the secrets file(s), all lowercase.
#-------------------------------------------------------------------------------
generateRandomDockerSecrets () {
  for FILE in "$@"; do
    local SECRET_FILE="$DOCKER_SECRETS_DIR/$FILE"
    local SECRET_VALUE="$(generateRandomString)"

    echoComment 'Generating a secret file at:'
    echoComment "$SECRET_FILE"
    echo "$SECRET_VALUE" >> "$SECRET_FILE"

    setPermissions '644' "$SECRET_FILE"
  done

  listDirectories "$DOCKER_SECRETS_DIR"
}