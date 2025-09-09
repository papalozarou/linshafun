#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for text generation and manipulation.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds a prefix to a string. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the string; and
# 2. "${2:?}" – the prefix to add.
#-------------------------------------------------------------------------------
addPrefix () {
  local STRING="${1:?}"
  local PREFIX="${2:?}"

  local STRING="$PREFIX$STRING"

  echo "$STRING"
}

#-------------------------------------------------------------------------------
# Adds a postfix to a string. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the string; and
# 2. "${2:?}" – the postfix to add.
# 
# N.B.
# If adding a file extension, the "." must be included at the start of the 
# second argument.
#-------------------------------------------------------------------------------
addPostfix () {
  local STRING="${1:?}"
  local POSTFIX="${2:?}"

  local STRING="$STRING$POSTFIX"

  echo "$STRING"
}

#-------------------------------------------------------------------------------
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
#-------------------------------------------------------------------------------
changeCase () {
  local STRING="${1:?}"
  local CASE="${2:?}"

  if [ "$CASE" = 'upper' ]; then
    STRING="$(echo "$STRING" | tr '[:lower:]' '[:upper:]')"
  elif [ "$CASE" = 'lower' ]; then
    STRING="$(echo "$STRING" | tr '[:upper:]' '[:lower:]')"
  elif [ "$CASE" = 'sentence' ]; then
    STRING="$(echo "$STRING" | sed 's/\<\([[:lower:]]\)\([^[:punct:]]*\)/\u\1\2/g')"
  fi

  echo "$STRING"
}

#-------------------------------------------------------------------------------
# Checks a string for a given substring. Takes two mandatory arguments:
#
# 1. "${1:?}" – the string; and
# 2. "${2:?}" – the substring to look for.
#
# POSIX parameter expansion is used to remove the substring from the string, and 
# then a check is performed to see if the result matches the originally passed 
# in string.
#
# The function returns true if the result of the parameter expansion doesn't 
# match the original string, i.e. the substring has been removed during the
# parameter expansion, and false if the result matches, i.e. the substring has 
# not been removed. As per:
#
# - https://stackoverflow.com/a/8811800
#-------------------------------------------------------------------------------
checkStringContainsSubstring() {
  local STRING="${1:?}"
  local SUBSTRING="${2:?}"

  if [ "${STRING#*"$SUBSTRING"}" != "$STRING" ]; then
    echo true
  else
    echo false
  fi
}

# ------------------------------------------------------------------------------
# Uncomments lines in files. Takes three arguments:
# 
# 1. "${1:?}" – the file containing the line to uncomment, including directory 
#    path;
# 2. "${2:?}" – the partial that the line starts with, without the comment
#    character, but including any delimiter, i.e. "=" or ":"; and
# 3. "${3:-#}" – an optional character used to comment out lines, defaulting to 
#    hash.
#
# The function allows for tabs or spaces before the commented out line and
# preserves indentations.
# 
# Partials are automatically escaped to enable sed to process partials 
# containing "/" characters.
# 
# N.B.
# The "if" statements do not use brackets because the exit status of the "grep"
# command is used directly as the condition, i.e. "grep" returns 0 – success – 
# if a match is found, or or 1 – failuare – if not.
#
# If the line is not found at all the script will exit.
# ------------------------------------------------------------------------------
commentInLine () {
  local FILE_PATH="${1:?}"
  local PARTIAL="${2:?}"
  local CHAR="${3:-#}"
  local ESCAPED_PARTIAL="$(printf '%s\n' "$PARTIAL" | sed 's/\//\\\//g')"

  if grep -q "^[[:space:]]*$PARTIAL" "$FILE_PATH"; then
    printComment 'The line starting with:'
    printComment "$PARTIAL"
    printComment 'is already uncommented in:'
    printComment "$FILE_PATH."
  elif grep -q "^[[:space:]]*$CHAR[[:space:]]*$PARTIAL" "$FILE_PATH"; then
    printComment 'Uncommenting line starting with:'
    printComment "$CHAR $PARTIAL"
    printComment 'in:'
    printComment "$FILE_PATH"
    sed -i "/^[[:space:]]*$CHAR[[:space:]]*$ESCAPED_PARTIAL/s/^\([[:space:]]*\)#[[:space:]]*/\1/" "$FILE_PATH"
  else
    printComment 'A line starting with:' 'warning'
    printComment "$PARTIAL" 'warning'
    printComment 'not found in:' 'warning'
    printComment "$FILE_PATH" 'warning'
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Comments out lines in files. Takes three arguments:
# 
# 1. "${1:?}" – the file containing the line to comment out, including directory
#    path;
# 2. "${2:?}" – the partial that the line starts with, without the comment
#    character, but including any delimiter, i.e. "=" or ":"; and
# 3. "${3:-#}" – an optional character used to comment out lines, defaulting to
#    hash.
# 
# The function allows for tabs or spaces before the line and preserves 
# indentations.
# 
# Partials are automatically escaped to enable sed to process partials 
# containing "/" characters.
# 
# N.B.
# The "if" statements do not use brackets because the exit status of the "grep"
# command is used directly as the condition, i.e. "grep" returns 0 – success – 
# if a match is found, or or 1 – failuare – if not.
#
# If the line is not found at all the script will exit.
# ------------------------------------------------------------------------------
commentOutLine () {
  local FILE_PATH="${1:?}"
  local PARTIAL="${2:?}"
  local CHAR="${3:-#}"
  local ESCAPED_PARTIAL="$(printf '%s\n' "$PARTIAL" | sed 's/\//\\\//g')"

  if grep -q "^[[:space:]]*$CHAR[[:space:]]*$PARTIAL" "$FILE_PATH"; then
    printComment 'The line starting with:'
    printComment "$PARTIAL"
    printComment 'is already commented out in:'
    printComment "$FILE_PATH."
  elif grep -q "^[[:space:]]*$PARTIAL" "$FILE_PATH"; then
    printComment 'Commenting out line starting with:'
    printComment "$PARTIAL"
    printComment 'in:'
    printComment "$FILE_PATH"
    sed -i "/^[[:space:]]*$ESCAPED_PARTIAL/s/^\([[:space:]]*\)/\1$CHAR /" "$FILE_PATH"
  else
    printComment 'A line starting with:' 'warning'
    printComment "$PARTIAL" 'warning'
    printComment 'not found in:' 'warning'
    printComment "$FILE_PATH" 'warning'
    return 1
  fi
}

#-------------------------------------------------------------------------------
# Generates a random alphanumeric string of a given length. Takes one argument:
# 
# 1. "${1:-"64"}" – the string length, defaults to 64.
#-------------------------------------------------------------------------------
generateRandomString () {
  local LENGTH="${1:-"64"}"
  local STRING="$(tr -cd '[:alnum:]' < /dev/urandom | fold -w "${LENGTH}" | head -n 1 | tr -d '\n')"

  echo "$STRING"
}

#-------------------------------------------------------------------------------
# Removes a prefix from a string. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the string; and
# 2. "${2:?}" – the prefix to remove.
# 
# The function uses pattern matching to trim the string, as per:
# 
# - https://unix.stackexchange.com/a/638638
#-------------------------------------------------------------------------------
removePrefix () {
  local STRING="${1:?}"
  local PREFIX="${2:?}"

  local STRING="${STRING#"$PREFIX"}"

  echo "$STRING"
}

#-------------------------------------------------------------------------------
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
#-------------------------------------------------------------------------------
removePostfix () {
  local STRING="${1:?}"
  local POSTFIX="${2:?}"

  local STRING="${STRING%"$POSTFIX"}"

  echo "$STRING"
}