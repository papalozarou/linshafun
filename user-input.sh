#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for getting user input.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Gets user input and returns it.
#-------------------------------------------------------------------------------
getUserInput () {
  read -r USER_INPUT

  echo "$USER_INPUT"
}

#-------------------------------------------------------------------------------
# Prompts for user input for consistency. Takes one or more arguments:
# 
# 1. "${1:?}" - the question to ask the user; and
# 2. "$i" – one or more warning lines, to allow for multiple lines.
# 
# The function takes the first argument as the question, then shifts the
# argument position by one and loops through each warning lines, as per:
# 
# - https://unix.stackexchange.com/a/225951
# 
# N.B.
# This function does not capture any user input, so must be used in conjunction 
# with "getUserInput".
#-------------------------------------------------------------------------------
promptForUserInput () {
  local QUESTION="${1:?}"
  
  echoComment "$QUESTION"

  shift

  if  [ "$#" -ge 1 ] ; then
    echoNb

    for i; do
      echoComment "$i"
    done
  fi
}