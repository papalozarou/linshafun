#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for controlling and manipulating docker services.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Controls a docker service, via docker compose. Takes at least two mandataory 
# arguments, with two different scenarios:
#
# 1. When Passing a compose file:
#    a. "${1:?}" – the compose file;
#    b. "${2:?}" - the action to perform;
#    c. "${3:?}" - the service to perform the action on; and
#    d. $4 - any optional flags.
# 2. Without passing a compose file:
#    a. "${1:?}" - the action to perform;
#    b. "${2:?}" - the service to perform the action on; and
#    c. $3 - any optional flags.
# 
# Because we are trying to be POSIX compliant "case" is used instead of "if" to 
# see if the first argument is a compose file. As per:
#
# - https://stackoverflow.com/a/19897118
# - https://www.shellscript.sh/case.html?cmdf=how+to+use+case+statement+sh
#-------------------------------------------------------------------------------
controlDockerService () {
  case "${1:?}" in
      *".yml")
        local COMPOSE_FILE="{$1:?}"
        local ACTION="${2:?}"
        local SERVICE="${3:?}"
        local FLAGS=$4
      ;;
      *)
        local COMPOSE_FILE="$COMPOSE_FILE"
        local ACTION="${2:?}"
        local SERVICE="${3:?}"
        local FLAGS=$4
      ;; 
  esac

  echoComment "Performing $ACTION for $SERVICE."
  echoSeparator

  if [ "$ACTION" = "up" ]; then
    sh -c "docker compose -f $COMPOSE_FILE $ACTION -d $SERVICE $FLAGS"
  else
    sh -c "docker compose -f $COMPOSE_FILE $ACTION $SERVICE $FLAGS"
  fi

  echoSeparator
  echoComment "$ACTION performed for $SERVICE."
}

#-------------------------------------------------------------------------------
# Starts and stops multiple related services. Takes at least two arguments:
# 
# 1. "${1:?}" - the action to be taken, either "up" or "stop"; or
# 2. "$i" – one or more services to perform the action on.
#-------------------------------------------------------------------------------
controlRelatedDockerServices () {
  local ACTION="${1:?}"

  shift

  for i; do
    if [ "$ACTION" = 'up' ]; then
      controlDockerService "$ACTION" "$i" '--no-deps'
    elif [ "$ACTION" = 'rm' ]; then
      controlDockerService "$ACTION" "$i" '-f'
    else 
      controlDockerService "$ACTION" "$i"
    fi
  done
}