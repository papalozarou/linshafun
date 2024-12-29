#!/bin/sh

#-------------------------------------------------------------------------------
# Functions to echo comments and help with comment consistency.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Comment variables.
#-------------------------------------------------------------------------------
COMMENT_PREFIX='SETUP SCRIPT:'
COMMENT_SEPARATOR='------------------------------------------------------------------'

#-------------------------------------------------------------------------------
# Echoes comments. Takes one mandatory argument:
# 
# 1. "${1:?}" – a comment.
#-------------------------------------------------------------------------------
echoComment () {
  local COMMENT="${1:?}"
  
  echo "$COMMENT_PREFIX $COMMENT"
}

#-------------------------------------------------------------------------------
# Echoes an "N.B." lines for consistency. Takes one or more arguments:
# 
# 1. "$@" – one or more comment lines to echo after the "N.B." header.
#-------------------------------------------------------------------------------
echoNb () {
  echoComment '****** N.B. ******'

  for COMMENT in "$@"; do
    echoComment "$COMMENT"
  done
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

  echoComment "To give $SERVICE time to $ACTION we will wait at least"
  echoComment "$WAIT seconds."
  echoNb
  echoComment 'Please do not stop the script.'
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
    echoComment 'Exiting script, however some changes were made – please review'
    echoComment 'the script output.'
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