#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for manipulating docker secrets
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Creates a docker secret. Takes two mandatory arguments:
# 
# 1. "${1:?}" - the secret value; and
# 2. "${2:?}" - the secret file, including directory path.
#-------------------------------------------------------------------------------
createDockerSecretFile () {
  local SECRET_VALUE="${1:?}"
  local SECRET_FILE="${2:?}"

  printComment 'Generating a secret file at:'
  printComment "$SECRET_FILE"
  echo "$SECRET_VALUE" >> "$SECRET_FILE"

  setPermissions '644' "$SECRET_FILE"

  listDirectories "$DOCKER_SECRETS_DIR"
}

#-------------------------------------------------------------------------------
# Creates "$DOCKER_SECRETS_DIR", first checking to see if it already exists. If
# it exists, do nothing. If it doesn't create it.
#-------------------------------------------------------------------------------
createDockerSecretsDir () {
  local DOCKER_SECRETS_DIR_TF="$(checkForFileOrDirectory "$DOCKER_SECRETS_DIR")"

  printComment 'Checking for a docker secrets directory at:'
  printComment "$DOCKER_SECRETS_DIR"

  if [ "$DOCKER_SECRETS_DIR_TF" = true ]; then
    printComment 'The docker secrets directory already exists.' 'warning'
  elif [ "$DOCKER_SECRETS_DIR_TF" = false ]; then
    createDirectory "$DOCKER_SECRETS_DIR"
    setPermissions '600' "$DOCKER_SECRETS_DIR"
  fi
}

#-------------------------------------------------------------------------------
# Generates a given named secret, using a random string. Takes one mandatory 
# argument:
# 
# 1. "${1:?}" - the secret file, including directory path.
#
# N.B.
# If the file already exists it is removed and recreated.
#-------------------------------------------------------------------------------
generateRandomDockerSecret () {
  local SECRET_FILE="${1:?}"
  local SECRET_VALUE="$(generateRandomString)"

  removeDockerSecretFile "$SECRET_FILE"

  printComment 'Generating a secret file at:'
  printComment "$SECRET_FILE"

  echo "$SECRET_VALUE" >> "$SECRET_FILE"

  setPermissions '644' "$SECRET_FILE"

  listDirectories "$DOCKER_SECRETS_DIR"
}

#-------------------------------------------------------------------------------
# Creates given named secrets by asking for user input. Takes one mandatory 
# argument and up to three optional ones:
# 
# 1. "${1:?}" - the secret file, including directory path; and
# 2. "$2" - optional warning to be displayed.
#
# N.B.
# If the file already exists it is removed and recreated.
#-------------------------------------------------------------------------------
getAndSetDockerSecret () {
  local SECRET_FILE="${1:?}"
  local WARNING="$2"

  removeDockerSecretFile "$SECRET_FILE"

  promptForUserInput "What value do you want to set for $SECRET_FILE?" "$WARNING"
  local SECRET_VALUE="$(getUserInput)"

  createDockerSecretFile "$SECRET_VALUE" "$SECRET_FILE"
}

#-------------------------------------------------------------------------------
# Reads the value of a given secret file. Takes one mandatory argument:
# 
# 1. "${1:?}" - the secrets file, including directory path.
#-------------------------------------------------------------------------------
readDockerSecretFile () {
  local SECRET_FILE="${1:?}"
  local SECRET_VALUE="$(cat "$SECRET_FILE")"

  echo "$SECRET_VALUE"
}

#-------------------------------------------------------------------------------
# Removes a given secret file. Takes one mandatory argument:
# 
# 1. "${1:?}" - the secrets file, including directory path.
#-------------------------------------------------------------------------------
removeDockerSecretFile () {
  local SECRET_FILE="${1:?}"

  if [ -f "$SECRET_FILE" ]; then
    removeFileOrDirectory "$SECRET_FILE"
  fi
}