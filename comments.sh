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
  echo "$COMMENT_PREFIX ${1:?}"
}

#-------------------------------------------------------------------------------
# Echose an "N.B." line for consistency.
#-------------------------------------------------------------------------------
echoNb () {
  echo "$COMMENT_PREFIX ****** N.B. ******"
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