#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for controlling and manipulating docker services.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Controls a docker service, via docker compose. Takes four arguments:
#
# 1. "${1:?}" – the compose file, including directory path and defaulting to
#    "$DKR_COMPOSE_FILE_PATH";
# 2. "${2:?}" – the action to perform;
# 3. "${3:?}" – the service to perform the action on; and
# 4. "$4" - any optional flags.
# 
# N.B.
# The optional flags, "$4", are not quoted as we explicitly want word splitting.
#
# Returns the exit status of "docker compose", so callers can stop if an action
# failed, i.e. not archiving a database whose service failed to stop.
#-------------------------------------------------------------------------------
controlDockerService () {
  local COMPOSE_FILE_PATH="${1:-$DKR_COMPOSE_FILE_PATH}"
  local ACTION="${2:?}"
  local SERVICE="${3:?}"
  local FLAGS="$4"

  printComment "Performing $ACTION for $SERVICE, using compose file:"
  printComment "$COMPOSE_FILE_PATH"
  printSeparator

  if [ "$ACTION" = "up" ]; then
    docker compose -f "$COMPOSE_FILE_PATH" "$ACTION" -d "$SERVICE" $FLAGS
  else
    docker compose -f "$COMPOSE_FILE_PATH" "$ACTION" "$SERVICE" $FLAGS
  fi

  local STATUS="$?"

  printSeparator
  ACTION="$(changeCase "$ACTION" 'sentence')"

  if [ "$STATUS" -ne 0 ]; then
    printComment "$ACTION failed for $SERVICE with exit status $STATUS." 'error'
    return "$STATUS"
  fi

  printComment "$ACTION performed for $SERVICE."
}

#-------------------------------------------------------------------------------
# Controls multiple related docker services. Takes at least two arguments:
#
# 1. "${1:?}" – the action to perform, such as "up", "stop", "rm" or "down"; and
# 2. "$@" – one or more services to perform the action on.
#
# N.B.
# Returns 1 if the action failed for any service, so callers can stop if an
# action failed. The remaining services are still acted on, so every failure is
# reported.
#-------------------------------------------------------------------------------
controlRelatedDockerServices () {
  local ACTION="${1:?}"
  local STATUS=0

  shift

  for SERVICE in "$@"; do
    if [ "$ACTION" = 'up' ]; then
      controlDockerService "" "$ACTION" "$SERVICE" '--no-deps' || STATUS=1
    elif [ "$ACTION" = 'rm' ]; then
      controlDockerService "" "$ACTION" "$SERVICE" '-f' || STATUS=1
    else 
      controlDockerService "" "$ACTION" "$SERVICE" || STATUS=1
    fi
  done

  return "$STATUS"
}