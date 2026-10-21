#!/bin/sh

# ------------------------------------------------------------------------------
# Functions for manipulating docker secrets.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Creates a docker secret. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the secret file, including directory path; and
# 2. "${2:?}" – the secret value.
# 
# An existing file at "$SECRET_FILE_PATH" is replaced, not appended to. The
# directory containing the file is then listed.
#
# Returns 1 if the secret file can't be written.
#
# N.B.
# The value is written with "printf '%s\n'", not "echo", so values such as
# "-n" or "a\nb" are written exactly as given. The file ends with a newline.
# ------------------------------------------------------------------------------
createDockerSecretFile () {
  local SECRET_FILE_PATH="${1:?}"
  local SECRET_VALUE="${2:?}"
  local STATUS=0

  printComment 'Generating a secret file at:'
  printComment -- "$SECRET_FILE_PATH"
  printf '%s\n' "$SECRET_VALUE" > "$SECRET_FILE_PATH" || STATUS="$?"

  if [ "$STATUS" -ne 0 ]; then
    printComment --error "Failed to write the secret file at $SECRET_FILE_PATH."

    return 1
  fi

  setPermissions '400' "$SECRET_FILE_PATH"

  listDirectories "${SECRET_FILE_PATH%/*}"
}

# ------------------------------------------------------------------------------
# Creates a docker secret by asking for user input. Takes two arguments: 
# 
# 1. "${1:?}" – the secret file, including directory path; and
# 2. "$2" – an optional warning to be displayed.
# ------------------------------------------------------------------------------
getAndSetDockerSecret () {
  local SECRET_FILE_PATH="${1:?}"
  local WARNING="$2"

  promptForUserInput "What value do you want to set for $SECRET_FILE_PATH?" "$WARNING"
  local SECRET_VALUE="$(getUserInput)"

  createDockerSecretFile "$SECRET_FILE_PATH" "$SECRET_VALUE"
}

# ------------------------------------------------------------------------------
# Reads the value of a secret file. Takes one mandatory argument:
# 
# 1. "${1:?}" – the secret file, including directory path.
# ------------------------------------------------------------------------------
readDockerSecretFile () {
  local SECRET_FILE_PATH="${1:?}"
  local SECRET_VALUE="$(cat "$SECRET_FILE_PATH")"

  echo "$SECRET_VALUE"
}

# ------------------------------------------------------------------------------
# Removes a secret file. Takes one mandatory argument:
# 
# 1. "${1:?}" – the secret file, including directory path.
# ------------------------------------------------------------------------------
removeDockerSecretFile () {
  local SECRET_FILE_PATH="${1:?}"

  printComment 'Removing the secret file at:'
  printComment -- "$SECRET_FILE_PATH"
  removeFilesOrDirectories "$SECRET_FILE_PATH"
}