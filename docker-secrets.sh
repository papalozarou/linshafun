#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for manipulating docker secrets.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Creates a docker secret. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the secret file name, either including or excluding the 
#    directory path; and
# 2. "${2:?}" – the secret value.
# 
# The function uses case to check if "$SECRET_FILE" contains "/" and sets
# "$SECRET_FILE_PATH" accordingly. An existing file at "$SECRET_FILE_PATH" is
# replaced, not appended to. The directory containing the file is then listed.
#
# Returns 1 if the secret file can't be written.
#
# N.B.
# The value is written with "printf '%s\n'", not "echo", so values such as
# "-n" or "a\nb" are written exactly as given. The file ends with a newline.
#-------------------------------------------------------------------------------
createDockerSecretFile () {
  local SECRET_FILE="${1:?}"
  local SECRET_VALUE="${2:?}"
  local SECRET_FILE_PATH
  local STATUS=0

  case "$SECRET_FILE" in
    */*) SECRET_FILE_PATH="$SECRET_FILE" ;;
    *)  SECRET_FILE_PATH="$DKR_SECRETS_DIR_PATH/$SECRET_FILE" ;;
  esac

  printComment 'Generating a secret file at:'
  printComment "$SECRET_FILE_PATH"
  printf '%s\n' "$SECRET_VALUE" > "$SECRET_FILE_PATH" || STATUS="$?"

  if [ "$STATUS" -ne 0 ]; then
    printComment "Failed to write the secret file at $SECRET_FILE_PATH." 'error'

    return 1
  fi

  setPermissions '400' "$SECRET_FILE_PATH"

  listDirectories "${SECRET_FILE_PATH%/*}"
}

#-------------------------------------------------------------------------------
# Creates a docker secret by asking for user input. Takes two arguments: 
# 
# 1. "${1:?}" – the secret file name, excluding directory path; and
# 2. "$2" – an optional warning to be displayed.
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
# 1. "${1:?}" – the secret file name, excluding directory path.
#-------------------------------------------------------------------------------
readDockerSecretFile () {
  local SECRET_FILE_NAME="${1:?}"
  local SECRET_VALUE="$(cat "$DKR_SECRETS_DIR_PATH/$SECRET_FILE_NAME")"

  echo "$SECRET_VALUE"
}

#-------------------------------------------------------------------------------
# Removes a secret file. Takes one mandatory argument:
# 
# 1. "${1:?}" – the secret file name, excluding directory path.
#-------------------------------------------------------------------------------
removeDockerSecretFile () {
  local SECRET_FILE_NAME="${1:?}"
  local SECRET_FILE_PATH="$DKR_SECRETS_DIR_PATH/$SECRET_FILE_NAME"

  printComment 'Removing the secret file at:'
  printComment "$SECRET_FILE_PATH"
  removeFileOrDirectory "$SECRET_FILE_PATH"
}