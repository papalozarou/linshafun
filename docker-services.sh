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
# The optional flags, "$4" are not quoted as we explicitly want word splitting.
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

  printSeparator
  ACTION="$(changeCase "$ACTION" 'sentence')"
  printComment "$ACTION performed for $SERVICE."
}

#-------------------------------------------------------------------------------
# Starts and stops multiple related services. Takes at least two arguments:
# 
# 1. "${1:?}" - the action to be taken, either "up" or "stop"; or
# 2. "$@" – one or more services to perform the action on.
#-------------------------------------------------------------------------------
controlRelatedDockerServices () {
  local ACTION="${1:?}"

  shift

  for SERVICE in "$@"; do
    if [ "$ACTION" = 'up' ]; then
      controlDockerService "" "$ACTION" "$SERVICE" '--no-deps'
    elif [ "$ACTION" = 'rm' ]; then
      controlDockerService "" "$ACTION" "$SERVICE" '-f'
    else 
      controlDockerService "" "$ACTION" "$SERVICE"
    fi
  done
}

#-------------------------------------------------------------------------------
# Stops all running service containers and runs "docker compose ps -a" as 
# a check.
#-------------------------------------------------------------------------------
stopRunningContainers () {
  printComment 'Stopping all running service containers…'
  printSeparator
  docker compose down

  printComment 'Running "docker compose ps -a" to check containers have stopped…'
  printSeparator
  docker compose ps -a
  printSeparator

  printComment 'Assuming no containers are listed above, all containers have been stopped.'
}