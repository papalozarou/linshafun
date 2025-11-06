#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for manipulating docker secrets.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Creates a docker secret. Takes two mandatory arguments:
# 
# 1. "${1:?}" - the secret file name, either including or excluding the 
#    directory path; and
# 2. "${2:?}" - the secret value.
# 
# The function uses case to check if "$SECRET_FILE" contains "/" and sets 
# "$SECRET_FILE_PATH" accordingly.
#-------------------------------------------------------------------------------
createDockerSecretFile () {
  local SECRET_FILE="${1:?}"
  local SECRET_VALUE="${2:?}"

  case "$SECRET_FILE" in
    */*) SECRET_FILE_PATH="$SECRET_FILE" ;;
    *)  SECRET_FILE_PATH="$DKR_SECRETS_DIR_PATH/$SECRET_FILE" ;;
  esac

  printComment 'Generating a secret file at:'
  printComment "$SECRET_FILE_PATH"
  echo "$SECRET_VALUE" >> "$SECRET_FILE_PATH"

  setPermissions '400' "$SECRET_FILE_PATH"

  listDirectories "$DKR_SECRETS_DIR_PATH"
}

#-------------------------------------------------------------------------------
# Creates a docker secrets directory at "$DKR_SECRETS_DIR_PATH", first checking 
# to see if it already exists. If it exists, do nothing. If it doesn't create it.
#-------------------------------------------------------------------------------
checkForAndCreateDockerSecretsDir () {
  local DKR_SECRETS_DIR_TF="$(checkForFileOrDirectory "$DKR_SECRETS_DIR_PATH")"

  printCheckResult 'to see if a docker secrets directory exists' "$DKR_SECRETS_DIR_TF"

  if [ "$DKR_SECRETS_DIR_TF" = true ]; then
    printComment 'The docker secrets directory already exists.' 'warning'
  elif [ "$DKR_SECRETS_DIR_TF" = false ]; then
    createDirectory "$DKR_SECRETS_DIR_PATH"
    setPermissions '600' "$DKR_SECRETS_DIR_PATH"
  fi
}

#-------------------------------------------------------------------------------
# Creates a docker secret by asking for user input. Takes two arguments: 
# 
# 1. "${1:?}" - the secret file name, excluding directory path; and
# 2. "$2" - an optional warning to be displayed.
#-------------------------------------------------------------------------------
getAndSetDockerSecret () {
  local SECRET_FILE_NAME="${1:?}"
  local WARNING="$2"

  promptForUserInput "What value do you want to set for $SECRET_FILE_NAME?" "$WARNING"
  local SECRET_VALUE="$(getUserInput)"

  createDockerSecretFile "$SECRET_FILE_NAME" "$SECRET_VALUE"
}

#-------------------------------------------------------------------------------
# Reads the value of a secret file. Takes one mandatory argument:
# 
# 1. "${1:?}" - the secret file name, excluding directory path.
#-------------------------------------------------------------------------------
readDockerSecretFile () {
  local SECRET_FILE_NAME="${1:?}"
  local SECRET_VALUE="$(cat "$DKR_SECRETS_DIR_PATH/$SECRET_FILE_NAME")"

  echo "$SECRET_VALUE"
}

#-------------------------------------------------------------------------------
# Removes a secret file. Takes one mandatory argument:
# 
# 1. "${1:?}" - the secret file name, excluding directory path.
#-------------------------------------------------------------------------------
removeDockerSecretFile () {
  local SECRET_FILE_NAME="${1:?}"
  local SECRET_FILE_PATH="$DKR_SECRETS_DIR_PATH/$SECRET_FILE_NAME"

  printComment 'Removing the secret file at:'
  printComment "$SECRET_FILE_PATH"
  removeFileOrDirectory "$SECRET_FILE_PATH"
}