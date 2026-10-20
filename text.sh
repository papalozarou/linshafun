#!/bin/sh

# ------------------------------------------------------------------------------
# Functions for text generation and manipulation.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Adds a prefix to a string. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the string; and
# 2. "${2:?}" – the prefix to add.
# ------------------------------------------------------------------------------
addPrefix () {
  local STRING="${1:?}"
  local PREFIX="${2:?}"

  local STRING="$PREFIX$STRING"

  echo "$STRING"
}

# ------------------------------------------------------------------------------
# Adds a postfix to a string. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the string; and
# 2. "${2:?}" – the postfix to add.
# 
# N.B.
# If adding a file extension, the "." must be included at the start of the 
# second argument.
# ------------------------------------------------------------------------------
addPostfix () {
  local STRING="${1:?}"
  local POSTFIX="${2:?}"

  local STRING="$STRING$POSTFIX"

  echo "$STRING"
}

# ------------------------------------------------------------------------------
# Changes the case of text. Takes two mandatory arguments:
# 
# 1. "${1:?}" – a text string; and
# 2. "${2:?}" – the required case.
# 
# Based on the following articles:
#
# - https://medium.com/mkdir-awesome/case-transformation-in-bash-and-posix-with-examples-acdc1e0d0bc4
# - https://tech.io/snippet/JCFhOEk
# - https://unix.stackexchange.com/a/554909
#
# N.B.
# Sentence case uses "awk" rather than "sed", as the "\<" and "\u" needed in
# "sed" are GNU extensions, which don't work in macOS or BusyBox "sed".
# ------------------------------------------------------------------------------
changeCase () {
  local STRING="${1:?}"
  local CASE="${2:?}"

  if [ "$CASE" = 'upper' ]; then
    STRING="$(echo "$STRING" | tr '[:lower:]' '[:upper:]')"
  elif [ "$CASE" = 'lower' ]; then
    STRING="$(echo "$STRING" | tr '[:upper:]' '[:lower:]')"
  elif [ "$CASE" = 'sentence' ]; then
    STRING="$(echo "$STRING" | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }')"
  fi

  echo "$STRING"
}

# ------------------------------------------------------------------------------
# Checks a file for a given string. Takes two mandatory arguments:
#
# 1. "${1:?}" – the file, including directory path; and
# 2. "${2:?}" – the string to look for.
#
# The function returns 0 if the string is found in the file, 1 if it is not, and
# 2 if the file can't be read, as it returns the status of "grep -q".
#
# N.B.
# The string is passed to "grep" as a regular expression, so a caller can
# anchor it, e.g. "^sshPort " matches only a line starting with "sshPort ".
# ------------------------------------------------------------------------------
checkFileContainsString () {
  local FILE_PATH="${1:?}"
  local STRING="${2:?}"

  grep -q "$STRING" "$FILE_PATH"
}

# ------------------------------------------------------------------------------
# Checks a string for a given substring. Takes two mandatory arguments:
#
# 1. "${1:?}" – the string; and
# 2. "${2:?}" – the substring to look for.
#
# POSIX parameter expansion is used to remove the substring from the string, and 
# then a check is performed to see if the result matches the originally passed 
# in string.
#
# The function returns 0 if the result of the parameter expansion doesn't 
# match the original string, i.e. the substring has been removed during the
# parameter expansion, and 1 if the result matches, i.e. the substring has 
# not been removed. As per:
#
# - https://stackoverflow.com/a/8811800
# ------------------------------------------------------------------------------
checkStringContainsSubstring () {
  local STRING="${1:?}"
  local SUBSTRING="${2:?}"

  [ "${STRING#*"$SUBSTRING"}" != "$STRING" ]
}

# ------------------------------------------------------------------------------
# Uncomments lines in files. Takes three arguments:
# 
# 1. "${1:?}" – the file containing the line to uncomment, including directory 
#    path;
# 2. "${2:?}" – the partial that the line starts with, without the comment
#    character, but including any delimiter, e.g. "=" or ":"; and
# 3. "${3:-#}" – an optional character used to comment out lines, defaulting to 
#    hash.
#
# The function allows for tabs or spaces before the commented out line and
# preserves indentations.
# 
# The "sed" command uses the control character "\001" as its separator.
# Partials are escaped so that "\", "[", ".", "*", "^" and "$" are matched
# literally, e.g. "[main]" only matches "[main]", not a line starting with "m",
# "a", "i" or "n".
# 
# N.B.
# The "if" statements do not use brackets because the exit status of the "grep"
# command is used directly as the condition, i.e. "grep" returns 0 – success – 
# if a match is found, or 1 – failure – if not.
#
# If the line is not found at all the function prints an error and returns 1.
# ------------------------------------------------------------------------------
commentInLine () {
  local FILE_PATH="${1:?}"
  local PARTIAL="${2:?}"
  local CHAR="${3:-#}"
  local SEPARATOR="$(printf '\001')"
  local ESCAPED_PARTIAL="$(printf '%s\n' "$PARTIAL" | sed 's/[[\.*^$]/\\&/g')"

  if grep -q "^[[:space:]]*${ESCAPED_PARTIAL}" "$FILE_PATH"; then
    printComment 'The line starting with:'
    printComment "$PARTIAL"
    printComment 'is already uncommented in:'
    printComment "$FILE_PATH."
  elif grep -q "^[[:space:]]*${CHAR}[[:space:]]*${ESCAPED_PARTIAL}" "$FILE_PATH"; then
    printComment 'Uncommenting line starting with:'
    printComment "$CHAR $PARTIAL"
    printComment 'in:'
    printComment "$FILE_PATH"
    sed -i "\\${SEPARATOR}^[[:space:]]*${CHAR}[[:space:]]*${ESCAPED_PARTIAL}${SEPARATOR}s${SEPARATOR}^\([[:space:]]*\)${CHAR}[[:space:]]*${SEPARATOR}\1${SEPARATOR}" "$FILE_PATH"
  else
    printComment 'A line starting with:' 'error'
    printComment "$PARTIAL" 'error'
    printComment 'not found in:' 'error'
    printComment "$FILE_PATH" 'error'
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Comments out lines in files. Takes three arguments:
# 
# 1. "${1:?}" – the file containing the line to comment out, including directory
#    path;
# 2. "${2:?}" – the partial that the line starts with, without the comment
#    character, but including any delimiter, e.g. "=" or ":"; and
# 3. "${3:-#}" – an optional character used to comment out lines, defaulting to
#    hash.
# 
# The function allows for tabs or spaces before the line and preserves 
# indentations.
# 
# The "sed" command uses the control character "\001" as its separator.
# Partials are escaped so that "\", "[", ".", "*", "^" and "$" are matched
# literally, e.g. "[main]" only matches "[main]", not a line starting with "m",
# "a", "i" or "n".
# 
# N.B.
# The "if" statements do not use brackets because the exit status of the "grep"
# command is used directly as the condition, i.e. "grep" returns 0 – success – 
# if a match is found, or 1 – failure – if not.
#
# If the line is not found at all the function prints an error and returns 1.
# ------------------------------------------------------------------------------
commentOutLine () {
  local FILE_PATH="${1:?}"
  local PARTIAL="${2:?}"
  local CHAR="${3:-#}"
  local SEPARATOR="$(printf '\001')"
  local ESCAPED_PARTIAL="$(printf '%s\n' "$PARTIAL" | sed 's/[[\.*^$]/\\&/g')"

  if grep -q "^[[:space:]]*${CHAR}[[:space:]]*${ESCAPED_PARTIAL}" "$FILE_PATH"; then
    printComment 'The line starting with:'
    printComment "$PARTIAL"
    printComment 'is already commented out in:'
    printComment "$FILE_PATH."
  elif grep -q "^[[:space:]]*${ESCAPED_PARTIAL}" "$FILE_PATH"; then
    printComment 'Commenting out line starting with:'
    printComment "$PARTIAL"
    printComment 'in:'
    printComment "$FILE_PATH"
    sed -i "\\${SEPARATOR}^[[:space:]]*${ESCAPED_PARTIAL}${SEPARATOR}s${SEPARATOR}^\([[:space:]]*\)${SEPARATOR}\1${CHAR} ${SEPARATOR}" "$FILE_PATH"
  else
    printComment 'A line starting with:' 'error'
    printComment "$PARTIAL" 'error'
    printComment 'not found in:' 'error'
    printComment "$FILE_PATH" 'error'
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Generates a random alphanumeric string of a given length. Takes one argument:
# 
# 1. "${1:-"64"}" – the string length, defaults to 64.
# ------------------------------------------------------------------------------
generateRandomString () {
  local LENGTH="${1:-"64"}"
  local STRING="$(tr -cd '[:alnum:]' < /dev/urandom | fold -w "${LENGTH}" | head -n 1 | tr -d '\n')"

  echo "$STRING"
}

# ------------------------------------------------------------------------------
# Gets the first characters of the first line of a file. Takes two mandatory
# arguments:
#
# 1. "${1:?}" – the file, including directory path; and
# 2. "${2:?}" – the number of characters to get.
# ------------------------------------------------------------------------------
getFirstCharsFromFirstLine () {
  local FILE_PATH="${1:?}"
  local CHAR_COUNT="${2:?}"
  local FIRST_CHARS="$(head -n 1 "$FILE_PATH" | cut -c "1-$CHAR_COUNT")"

  echo "$FIRST_CHARS"
}

# ------------------------------------------------------------------------------
# Removes a prefix from a string. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the string; and
# 2. "${2:?}" – the prefix to remove.
# 
# The function uses pattern matching to trim the string, as per:
# 
# - https://unix.stackexchange.com/a/638638
# ------------------------------------------------------------------------------
removePrefix () {
  local STRING="${1:?}"
  local PREFIX="${2:?}"

  local STRING="${STRING#"$PREFIX"}"

  echo "$STRING"
}

# ------------------------------------------------------------------------------
# Removes a postfix from a string. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the string; and
# 2. "${2:?}" – the postix to remove.
# 
# The function uses pattern matching to trim the string, as per:
# 
# - https://unix.stackexchange.com/a/638638
# 
# N.B.
# If removing a file extension, you must include the "." at the start of the 
# second argument.
# ------------------------------------------------------------------------------
removePostfix () {
  local STRING="${1:?}"
  local POSTFIX="${2:?}"

  local STRING="${STRING%"$POSTFIX"}"

  echo "$STRING"
}