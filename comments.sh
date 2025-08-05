#!/bin/sh

#-------------------------------------------------------------------------------
# Functions to echo comments and help with comment consistency.
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
COMMENT_PREFIX_WARN='NOTA BENE: '
COMMENT_SEPARATOR='------------------------------------------------------------------'

#-------------------------------------------------------------------------------
# Prints a comment. Takes two arguments:
# 
# 1. "${1:?}" – the full comment to echo; and
# 2. "${2:-false}" – a flag indicating if the comment is a warning, defaulting 
#    to false.
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
echoComment () {
  local COMMENT="${1:?}"
  local WARN_TF="${2:-false}"

  if [ "$WARN_TF" = true ]; then
    local LINE_LENGTH=69
  else
    local LINE_LENGTH=66
  fi

  CURRENT_LINE=

  for WORD in $COMMENT; do
    if [ -z "$CURRENT_LINE" ]; then
      CURRENT_LINE="$WORD"
    elif [ $((${#CURRENT_LINE} + ${#WORD} + 1)) -le "$LINE_LENGTH" ]; then
      CURRENT_LINE="$CURRENT_LINE $WORD"
    elif [ "$WARN_TF" = true ]; then
      printComment "$CURRENT_LINE" true
      CURRENT_LINE="$WORD"
    else
      printComment "$CURRENT_LINE"
      CURRENT_LINE="$WORD"
    fi
  done

  if [ -n "$CURRENT_LINE" ] && [ "$WARN_TF" = true ]; then
    printComment "$CURRENT_LINE" true
  elif [ -n "$CURRENT_LINE" ]; then
    printComment "$CURRENT_LINE"
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
echoServiceWait () {
  local SERVICE="${1:?}"
  local ACTION="${2:?}"
  local WAIT="${3:-"60"}"

  echoComment "To give $SERVICE time to $ACTION we will wait at least $WAIT seconds."
  echoComment 'Please do not stop the script.' true
  
  sleep "$WAIT"
}

#-------------------------------------------------------------------------------
# Echoes that the script is exiting. Takes one optional argument:
#
# 1. $1 - flag for if exiting with changes.
# 
# If the flag is "true" the function will print the additional "changes were
# made" output.
#-------------------------------------------------------------------------------
echoScriptExiting () {
  echoSeparator

  if [ "$1" = true ]; then
    echoComment 'Exiting script, however some changes were made – please review the script output.' true
  else
    echoComment 'Exiting script with no changes.'
  fi

  echoSeparator
}

#-------------------------------------------------------------------------------
# Echoes that the script has finished. Takes no arguments.
#-------------------------------------------------------------------------------
echoScriptFinished () {
  echoSeparator
  echoComment 'Script finished.'
  echoSeparator
}

#-------------------------------------------------------------------------------
# Echoes comment separator. Takes no arguments.
#-------------------------------------------------------------------------------
echoSeparator () {
  echoComment "$COMMENT_SEPARATOR"
}

#-------------------------------------------------------------------------------
# Prints a comment line with the specified prefix and colour. Takes two
# arguments:
# 
# 1. "${1:?}" – the comment line to print; and
# 2. "${2:-false}" – a flag indicating if the line is a warning line, defaulting
#    to "false".
#
# The comment line is printed in the specified colour, with the appropriate 
# prefix. If the second argument is "true", it uses the warning prefix and 
# colour.
# 
# N.B.
# The "COMMENT_COLOUR_PREFIX" and "COMMENT_COLOUR_WARN" variables are used to
# differentiate between regular comments and warning comments.
# 
# In the "printf" commands:
# 
# - "%b" interprets escape sequences in the corresponding argument, allowing the
#   use of ANSI escape codes for colour formatting;
# - "%s" prints a string; and
# - "\n" is used to ensure that each line ends properly, especially when the 
#   last line does not reach the maximum length.
#-------------------------------------------------------------------------------
printComment () {
  local LINE="${1:?}"
  local WARN_TF="${2:-false}"

  if [ "$WARN_TF" = true ]; then
    printf "%b%s%s\n" "$COMMENT_COLOUR_WARN" "$COMMENT_PREFIX_WARN" "$LINE"
  else
    printf "%b%s%b%s\n" "$COMMENT_COLOUR_PREFIX" "$COMMENT_PREFIX" "$COMMENT_COLOUR_RESET" "$LINE"
  fi
}