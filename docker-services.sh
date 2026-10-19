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
# Controls every service in a docker compose stack. Takes three arguments:
#
# 1. "${1:?}" – the compose file, including directory path and defaulting to
#    "$DKR_COMPOSE_FILE_PATH";
# 2. "${2:?}" – the action to perform; and
# 3. "$3" – any optional flags.
#
# N.B.
# The optional flags, "$3", are not quoted as we explicitly want word splitting.
#
# Returns the exit status of "docker compose", so callers can stop if an action
# failed.
#-------------------------------------------------------------------------------
controlDockerStack () {
  local COMPOSE_FILE_PATH="${1:-$DKR_COMPOSE_FILE_PATH}"
  local ACTION="${2:?}"
  local FLAGS="$3"

  printComment "Performing $ACTION for the stack, using compose file:"
  printComment "$COMPOSE_FILE_PATH"
  printSeparator

  if [ "$ACTION" = "up" ]; then
    docker compose -f "$COMPOSE_FILE_PATH" "$ACTION" -d $FLAGS
  else
    docker compose -f "$COMPOSE_FILE_PATH" "$ACTION" $FLAGS
  fi

  local STATUS="$?"

  printSeparator
  ACTION="$(changeCase "$ACTION" 'sentence')"

  if [ "$STATUS" -ne 0 ]; then
    printComment "$ACTION failed for the stack with exit status $STATUS." 'error'
    return "$STATUS"
  fi

  printComment "$ACTION performed for the stack."
}

#-------------------------------------------------------------------------------
# Controls every service in multiple docker compose stacks. Takes at least two
# arguments:
#
# 1. "${1:?}" – the action to perform, such as "up", "stop" or "pull"; and
# 2. "$@" – one or more stack directory paths, i.e.
#    "/volume1/docker/stack-one".
#
# Each stack's compose file is found with "getDockerComposeFilePath", then
# the action is performed via "controlDockerStack".
#
# N.B.
# Returns 1 if the action failed for any stack, so callers can stop if an
# action failed. The remaining stacks are still acted on, so every failure is
# reported.
#-------------------------------------------------------------------------------
controlDockerStacks () {
  local ACTION="${1:?}"
  local STACK_DIR_PATH
  local STATUS=0

  shift

  for STACK_DIR_PATH in "$@"; do
    controlDockerStack "$(getDockerComposeFilePath "$STACK_DIR_PATH")" "$ACTION" || STATUS=1
  done

  return "$STATUS"
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

#-------------------------------------------------------------------------------
# Gets the compose file path for a docker compose stack. Takes one mandatory
# argument:
#
# 1. "${1:?}" – the stack directory path, i.e. "/volume1/docker/stack-one".
#
# Echoes "<stack directory path>/compose.yml" if it exists, otherwise
# "<stack directory path>/docker-compose.yml".
#
# N.B.
# "docker compose -f" needs an exact file path, so Compose's own search for a
# compose file in the working directory is not used. Only the ".yml" names are
# checked.
#
# If neither file exists, the "docker compose" command given the path fails,
# which callers already treat as a failed action.
#
# - https://docs.docker.com/compose/intro/compose-application-model/
# - https://docs.docker.com/reference/cli/docker/compose/
#-------------------------------------------------------------------------------
getDockerComposeFilePath () {
  local STACK_DIR_PATH="${1:?}"
  local COMPOSE_FILE_PATH="$STACK_DIR_PATH/compose.yml"

  if ! checkForFileOrDirectory "$COMPOSE_FILE_PATH"; then
    COMPOSE_FILE_PATH="$STACK_DIR_PATH/docker-compose.yml"
  fi

  echo "$COMPOSE_FILE_PATH"
}