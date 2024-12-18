#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for text generation and manipulation.
#-------------------------------------------------------------------------------

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
# Generates a random alphanumeric string of a given length. Takes one argument:
# 
# 1. "${1:-"64"}" – the string length, defaults to 64.
#-------------------------------------------------------------------------------
generateRandomString () {
  local LENGTH="${1:-"64"}"
  local STRING="$(tr -cd '[:alnum:]' < /dev/urandom | fold -w "${LENGTH}" | head -n 1 | tr -d '\n')"

  echo "$STRING"
}

