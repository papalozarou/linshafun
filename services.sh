#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for controling services.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Starts, stops or restarts a service. Takes two mandatory arguments:
#  
# 1. "${1:?}" – specifying the action; and
# 2. "${2:?}" – the service to perform the action on.
#-------------------------------------------------------------------------------
controlService () {
  local ACTION="${1:?}"
  local SERVICE="${2:?}"

  printComment "Performing $ACTION for $SERVICE."

  if [ "$SERVICE" = 'ufw' ]; then
    "$SERVICE" "$ACTION"
  else
    systemctl "$ACTION" "$SERVICE"
  fi
  
  ACTION="$(changeCase "$ACTION" 'sentence')"
  printSeparator
  printComment "$ACTION performed for $SERVICE."
}