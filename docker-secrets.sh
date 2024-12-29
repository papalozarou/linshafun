#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for manipulating docker secrets
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Creates "$DOCKER_SECRETS_DIR", first checking to see if it already exists. If
# it exists, do nothing. If it doesn't create it.
#-------------------------------------------------------------------------------
createDockerSecretsDir () {
  local DOCKER_SECRETS_DIR_TF="$(checkForFileOrDirectory "$DOCKER_SECRETS_DIR")"

  echoComment 'Checking for a docker secrets directory at:'
  echoComment "$DOCKER_SECRETS_DIR"

  if [ "$DOCKER_SECRETS_DIR_TF" = true ]; then
    echoComment 'The docker secrets directory already exists.'
  elif [ "$DOCKER_SECRETS_DIR_TF" = false ]; then
    createDirectory "$DOCKER_SECRETS_DIR"
    setPermissions '600' "$DOCKER_SECRETS_DIR"
  fi
}

#-------------------------------------------------------------------------------
# Generates a given named secret, using a random string. Takes one mandatory 
# argument:
# 
# 1. "${1:?}" - the name of the secrets file, all lowercase.
#
# N.B.
# If the file already exists it is removed and recreated.
#-------------------------------------------------------------------------------
generateRandomDockerSecrets () {
  local SECRET_FILE="$DOCKER_SECRETS_DIR/${1:?}"
  local SECRET_VALUE="$(generateRandomString)"

  if [ -f "$SECRET_FILE" ]; then
    removeFileOrDirectory "$SECRET_FILE"
  fi

  echoComment 'Generating a secret file at:'
  echoComment "$SECRET_FILE"

  echo "$SECRET_VALUE" >> "$SECRET_FILE"

  setPermissions '644' "$SECRET_FILE"

  listDirectories "$DOCKER_SECRETS_DIR"
}

#-------------------------------------------------------------------------------
# Creates given named secrets by asking for user input. Takes one mandatory 
# argument and up to three optional ones:
# 
# 1. "${1:?}" - the name of the secrets file, all lowercase; and
# 2. "$2|3|4" - optional lines to be echoed as "N.B." comments.
#
# "shift" is used to move variable "$2" to variable position "$1", to allow the 
# remaining variables to be passed through to ""promptForUserInput" as a group 
# using "$@". As per:
#
# - https://unix.stackexchange.com/a/174568
# 
# N.B.
# If the file already exists it is removed and recreated.
#-------------------------------------------------------------------------------
getAndSetDockerSecrets () {
  local FILE="${1:?}"
  local SECRET_FILE="$DOCKER_SECRETS_DIR/$FILE"
  local NB_LINE_1="$2"
  local NB_LINE_2="$3"
  local NB_LINE_3="$4"

  if [ -f "$SECRET_FILE" ]; then
    removeFileOrDirectory "$SECRET_FILE"
  fi

  shift

  promptForUserInput "What value do you want to set for $FILE?" "$@"
  local SECRET_VALUE="$(getUserInput)"

  echoComment 'Generating a secret file at:'
  echoComment "$SECRET_FILE"
  echo "$SECRET_VALUE" >> "$SECRET_FILE"

  setPermissions '644' "$SECRET_FILE"

  listDirectories "$DOCKER_SECRETS_DIR"
}