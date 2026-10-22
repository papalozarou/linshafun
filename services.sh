#!/bin/sh

# ------------------------------------------------------------------------------
# Functions for controlling services.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Starts, stops or restarts a service. Takes two mandatory arguments:
#  
# 1. "${1:?}" – specifying the action; and
# 2. "${2:?}" – the service to perform the action on.
#
# If "ufw" or "systemctl" fails, the function prints an error and returns 1.
#
# N.B.
# "systemctl status" returns 3 when the service isn't running, so a "status"
# action on a stopped service is reported as failed.
# ------------------------------------------------------------------------------
controlService () {
  local ACTION="${1:?}"
  local SERVICE="${2:?}"
  local STATUS=0

  printComment "Performing $ACTION for $SERVICE."

  if [ "$SERVICE" = 'ufw' ]; then
    "$SERVICE" "$ACTION" || STATUS=1
  else
    systemctl "$ACTION" "$SERVICE" --no-pager || STATUS=1
  fi
  
  ACTION="$(changeCase "$ACTION" 'sentence')"
  printSeparator

  if [ "$STATUS" -ne 0 ]; then
    printComment --error -- "$ACTION failed for $SERVICE."

    return 1
  fi

  printComment -- "$ACTION performed for $SERVICE."
}