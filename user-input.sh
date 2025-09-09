#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for getting user input.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Gets user input and returns it.
#-------------------------------------------------------------------------------
getUserInput () {
  read -r USER_INPUT

  printf "%s\n" "$USER_INPUT"
}

#-------------------------------------------------------------------------------
# Specifically gets "y/Y" or "n/N" input, forcing user to chose one. Returns
# true for "y/Y" and false for "n/N".
#-------------------------------------------------------------------------------
getUserInputYN () {
  local INPUT_YN="$(getUserInput)"

  if [ "$INPUT_YN" = "y" ] || [ "$INPUT_YN" = "Y" ]; then
    echo true
  elif [ "$INPUT_YN" = "n" ] || [ "$INPUT_YN" = "N" ]; then
    echo false
  else
    printComment 'You must respond y/Y or n/N to proceed.' 'warning'
    getUserInputYN
  fi
}

#-------------------------------------------------------------------------------
# Prompts for user input for consistency. Takes two arguments:
# 
# 1. "${1:?}" - the question to ask the user; and
# 2. "$2" – an optional warning message.
# 
# The function takes the first argument as the question, then shifts the
# argument position by one and prints any warning line.
# 
# N.B.
# This function does not capture any user input, so must be used in conjunction 
# with "getUserInput".
#-------------------------------------------------------------------------------
promptForUserInput () {
  local QUESTION="${1:?}"
  
  printComment "$QUESTION"

  shift

  if  [ "$#" -ge 1 ]; then
    printComment "$1" 'warning'
  fi
}