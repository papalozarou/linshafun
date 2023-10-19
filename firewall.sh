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
#-------------------------------------------------------------------------------
addRuleToUfw () {
  local ACTION="${1:?}"
  local PORT="${2:?}"
  local PROTOCOL="$3"

  if [ -z "$PROTOCOL" ]; then
      echoComment "Adding rule $ACTION $PORT to UFW."
      echoSeparator
      sh -c "ufw $ACTION $PORT"
      echoSeparator
  else
    echoComment "Adding rule $ACTION $PORT/$PROTOCOL to UFW."
    echoSeparator
    sh -c "ufw $ACTION $PORT/$PROTOCOL"
    echoSeparator
  fi

  echoComment 'Rule added.'
}

#-------------------------------------------------------------------------------
# Lists current ufw rules, with numbers.
#-------------------------------------------------------------------------------
listUfwRules () {
  echoComment 'Listing UFW rules…'
  echoSeparator
  sh -c "ufw status numbered"
  echoSeparator
}