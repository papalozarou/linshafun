#!/bin/sh

#-------------------------------------------------------------------------------
# Functions to check and add rules to ufw.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds a port to ufw. Takes three arguments:
#
# 1. "${1:?}" – a mandatory action, either "allow", "deny" or "limit";
# 2. "${2:?}" – a mandatory port number; and
# 3. "$3" – an optional protocol
#
# If "ufw" fails, the function prints an error and returns 1.
#-------------------------------------------------------------------------------
addRuleToUfw () {
  local ACTION="${1:?}"
  local PORT="${2:?}"
  local PROTOCOL="$3"
  local STATUS=0

  if [ -z "$PROTOCOL" ]; then
      printComment "Adding rule $ACTION $PORT to UFW."
      printSeparator
      ufw "$ACTION" "$PORT" || STATUS="$?"
      printSeparator
  else
    printComment "Adding rule $ACTION $PORT/$PROTOCOL to UFW."
    printSeparator
    ufw "$ACTION" "$PORT/$PROTOCOL" || STATUS="$?"
    printSeparator
  fi

  if [ "$STATUS" -ne 0 ]; then
    printComment "Failed to add rule $ACTION $PORT to UFW." 'error'

    return 1
  fi

  printComment 'Rule added.'
}

#-------------------------------------------------------------------------------
# Lists current ufw rules, with numbers. Takes no arguments.
#-------------------------------------------------------------------------------
listUfwRules () {
  printComment 'Listing UFW rules…'
  printSeparator
  ufw status numbered
  printSeparator
}