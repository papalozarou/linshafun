#!/bin/sh

# ------------------------------------------------------------------------------
# Functions for getting user input.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Gets user input and returns it. Takes no arguments.
# ------------------------------------------------------------------------------
getUserInput () {
  local USER_INPUT=

  read -r USER_INPUT

  printf "%s\n" "$USER_INPUT"
}

# ------------------------------------------------------------------------------
# Specifically gets "y/Y" or "n/N" input, forcing the user to choose one. 
# Returns 0 for "y/Y" and 1 for "n/N". Takes no arguments.
#
# N.B.
# Any other input prints an error and asks again. The function then returns the
# status of that repeated call.
# ------------------------------------------------------------------------------
getUserInputYN () {
  local INPUT_YN="$(getUserInput)"

  if [ "$INPUT_YN" = "y" ] || [ "$INPUT_YN" = "Y" ]; then
    return 0
  elif [ "$INPUT_YN" = "n" ] || [ "$INPUT_YN" = "N" ]; then
    return 1
  else
    printComment --error 'You must respond y/Y or n/N to proceed.'
    getUserInputYN
  fi
}

# ------------------------------------------------------------------------------
# Prompts for user input for consistency. Takes two arguments:
# 
# 1. "${1:?}" – the question to ask the user; and
# 2. "$2" – an optional warning message.
# 
# The function takes the first argument as the question, then shifts the
# argument position by one and prints any warning line.
# 
# N.B.
# This function does not capture any user input, so must be used in conjunction 
# with "getUserInput".
# ------------------------------------------------------------------------------
promptForUserInput () {
  local QUESTION="${1:?}"
  
  printComment -- "$QUESTION"

  shift

  if  [ "$#" -ge 1 ]; then
    printComment --warning -- "$1"
  fi
}
