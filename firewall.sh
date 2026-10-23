#!/bin/sh

# ------------------------------------------------------------------------------
# Functions to check and add rules to ufw.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Adds a rule to ufw. Takes five mandatory arguments, in the order ufw reads
# them:
#
# 1. "${1:?}" – an action, either "allow", "deny" or "limit";
# 2. "${2:?}" – a source address or range, e.g. "192.0.2.0/24", or "any";
# 3. "${3:?}" – a port, e.g. "53", or a range, e.g. "8000:8100";
# 4. "${4:?}" – a protocol, either "tcp", "udp" or "any"; and
# 5. "${5:?}" – a comment, e.g. "Pi-hole DNS".
#
# If "ufw" fails, the function prints an error and returns 1.
#
# N.B.
# A source and protocol of "any" add the same rule as "ufw allow 53", i.e. for
# tcp and udp. A port range needs "tcp" or "udp". ufw rejects a comment
# containing "'".
# ------------------------------------------------------------------------------
addRuleToUfw () {
  local ACTION="${1:?}"
  local SOURCE="${2:?}"
  local PORT="${3:?}"
  local PROTOCOL="${4:?}"
  local COMMENT="${5:?}"
  local RULE="$ACTION from $SOURCE to any port $PORT proto $PROTOCOL"
  local STATUS=0

  printComment "Adding UFW rule \"$COMMENT\": $RULE."
  printSeparator
  ufw "$ACTION" from "$SOURCE" to any port "$PORT" proto "$PROTOCOL" comment "$COMMENT" || STATUS=1
  printSeparator

  if [ "$STATUS" -ne 0 ]; then
    printComment --error "Failed to add UFW rule \"$COMMENT\": $RULE."

    return 1
  fi

  printComment 'Rule added.'
}

# ------------------------------------------------------------------------------
# Lists current ufw rules, with numbers. Takes no arguments.
# ------------------------------------------------------------------------------
listUfwRules () {
  printComment 'Listing UFW rules…'
  printSeparator
  ufw status numbered
  printSeparator
}