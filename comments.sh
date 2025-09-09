#!/bin/sh

#-------------------------------------------------------------------------------
# Functions to print comments and help with comment consistency.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Comment variables.
#
# N.B.
# "COMMENT_COLOUR_PREFIX" and "COMMENT_COLOUR_WARN" use the ANSI escape code for
# green and yellow respectively. The "COMMENT_COLOUR_RESET" variable resets the 
# ANSI colour.
# 
# Yes, yes we are using the latin phrase, not the abbreviation, for 
# "COMMENT_PREFIX_WARN".
#-------------------------------------------------------------------------------
COMMENT_COLOUR_PREFIX='\033[32m'
COMMENT_COLOUR_WARN='\033[33m'
COMMENT_COLOUR_ERROR='\033[31m'
COMMENT_COLOUR_RESET='\033[0m'
COMMENT_PREFIX='SETUP SCRIPT: '
COMMENT_PREFIX_WARN='   NOTA BENE: '
COMMENT_PREFIX_ERROR=' ***ERROR***: '
COMMENT_SEPARATOR='------------------------------------------------------------------'

#-------------------------------------------------------------------------------
# Prints a comment of any length, via "printLine". Takes two arguments:
# 
# 1. "${1:?}" – the full comment to print; and
# 2. "${2:-regular}" – a flag indicating if the comment is "regular", a 
#    "warning", or an "error", defaulting to "regular".
# 
# The comment is split into words and printed in lines that do not exceed the
# standard terminal length of 80 characters, including prefix.
# 
# The function handles line breaks and ensures that the last line is printed 
# even if it does not reach the maximum length, via the last for loop.
# 
# N.B.
# "$COMMENT_LINE" is not quoted in the for loop to allow for word splitting when
# it is parsed.
#-------------------------------------------------------------------------------
printComment () {
  local COMMENT="${1:?}"
  local COMMENT_TYPE="${2:-regular}"
  local LINE_LENGTH=66

  CURRENT_LINE=

  for WORD in $COMMENT; do
    if [ -z "$CURRENT_LINE" ]; then
      CURRENT_LINE="$WORD"
    elif [ $((${#CURRENT_LINE} + ${#WORD} + 1)) -le "$LINE_LENGTH" ]; then
      CURRENT_LINE="$CURRENT_LINE $WORD"
    elif [ "$WARN_TF" = true ]; then
      printLine "$CURRENT_LINE" true
      CURRENT_LINE="$WORD"
    else
      printLine "$CURRENT_LINE"
      CURRENT_LINE="$WORD"
    fi
  done

  printLine "$CURRENT_LINE" "$FLAG"
}

#-------------------------------------------------------------------------------
# Prints a comment line with the specified prefix and colour. Takes two
# arguments:
# 
# 1. "${1:?}" – the comment line to print; and
# 2. "${2:-regular}" – a flag indicating if the comment is "regular", a 
#    "warning", or an "error", defaulting to "regular".
#
# The comment line is printed in the specified colour, with the appropriate 
# prefix.
# 
# N.B.
# In the "printf" commands:
# 
# - "%b" interprets escape sequences in the corresponding argument, allowing the
#   use of ANSI escape codes for colour formatting;
# - "%s" prints a string; and
# - "\n" is used to ensure that each line ends properly, especially when the 
#   last line does not reach the maximum length.
#-------------------------------------------------------------------------------
printLine () {
  local LINE="${1:?}"
  local TYPE="${2:-regular}"

  if [ "$TYPE" = true ]; then
    printf "%b%s%s\n%b" "$COMMENT_COLOUR_WARN" "$COMMENT_PREFIX_WARN" "$LINE" "$COMMENT_COLOUR_RESET"
  elif [ "$TYPE" = 'error' ]; then
    printf "%b%s%s\n%b" "$COMMENT_COLOUR_ERROR" "$COMMENT_PREFIX_ERROR" "$LINE" "$COMMENT_COLOUR_RESET"
  else
    printf "%b%s%b%s\n" "$COMMENT_COLOUR_PREFIX" "$COMMENT_PREFIX" "$COMMENT_COLOUR_RESET" "$LINE"
  fi
}

#-------------------------------------------------------------------------------
# Tells the user an action is taking place and a wait is needed. Takes three
# mandatory arguments:
# 
# 1. "${1:?}" - the service the action is being performed on;
# 2. "${2:?}" - the action being performed; and
# 3. "${3:-"60"}" - the length of time, in seconds to wait, defaults to 60.
#-------------------------------------------------------------------------------
printServiceWait () {
  local SERVICE="${1:?}"
  local ACTION="${2:?}"
  local WAIT="${3:-"60"}"

  printComment "To give $SERVICE time to $ACTION we will wait at least $WAIT seconds."
  printComment 'Please do not stop the script.' 'warning'
  
  sleep "$WAIT"
}

#-------------------------------------------------------------------------------
# Tells the user that the script is exiting. Takes one optional argument:
#
# 1. $1 - flag for if exiting with changes.
# 
# If the flag is "true" the function will print the additional "changes were
# made" output.
#-------------------------------------------------------------------------------
printScriptExiting () {
  printSeparator

  if [ "$1" = true ]; then
    printComment 'Exiting script, however some changes were made – please review the script output.' 'warning'
  else
    printComment 'Exiting script with no changes.'
  fi

  printSeparator
}

#-------------------------------------------------------------------------------
# Tells the user that the script has finished. Takes no arguments.
#-------------------------------------------------------------------------------
printScriptFinished () {
  printSeparator
  printComment 'Script finished.'
  printSeparator
}

#-------------------------------------------------------------------------------
# Prints comment separator. Takes no arguments.
#-------------------------------------------------------------------------------
printSeparator () {
  printComment "$COMMENT_SEPARATOR"
}