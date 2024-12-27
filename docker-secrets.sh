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
#-------------------------------------------------------------------------------
generateRandomDockerSecrets () {
  local SECRET_FILE="$DOCKER_SECRETS_DIR/${1:?}"
  local SECRET_VALUE="$(generateRandomString)"

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
# The function checks to see if "$2|3|4" are non-zero, and if so passes the
# optional arguments to the "echoNb" function.
#-------------------------------------------------------------------------------
getAndSetDockerSecrets () {
  local SECRET_FILE="$DOCKER_SECRETS_DIR/${1:?}"
  local NB_LINE_1="$2"
  local NB_LINE_2="$3"
  local NB_LINE_3="$4"

  echoComment "What value do you want to set for $FILE?"

  if [ -n "$NB_LINE_3" ]; then
    echoNb "$NB_LINE_1" "$NB_LINE_2" "$NB_LINE_3"
  elif [ -n "$NB_LINE_2" ]; then
    echoNb "$NB_LINE_1" "$NB_LINE_2"
  else
    echoNb "$NB_LINE_1"
  fi

  local SECRET_VALUE="$(getUserInput)"

  echoComment 'Generating a secret file at:'
  echoComment "$SECRET_FILE"
  echo "$SECRET_VALUE" >> "$SECRET_FILE"

  setPermissions '644' "$SECRET_FILE"

  listDirectories "$DOCKER_SECRETS_DIR"
}