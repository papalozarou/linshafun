#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for manipulating docker volumes.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Lists the contents of docker volumes. Takes one or more arguments
# 
# 1. "${1:?}" – the prefix for the volumes; and
# 2. "$i" – the volume or volumes to be listed, including prefix
#-------------------------------------------------------------------------------
listVolumeContents () {
  local PREFIX="${1:?}"
  
  for i; do
    local VOLUME="$PREFIX_$i"

    echoComment 'Listing contents of the following docker volume:'
    echoComment "$VOLUME"

    echoSeparator
    docker run --rm -i -v="$VOLUME":/tmp/myvolume busybox ls -lna -R /tmp/myvolume
    echoSeparator
  done
}

#-------------------------------------------------------------------------------
# Manages docker volumes. Takes at least two mandatory arguments:
#
# 1. "${1:?}" – the action to perform; 
# 2. "${2:?}" – the prefix for the volumes; and
# 2. "$i" – one ore more volumes.
#-------------------------------------------------------------------------------
manageDockerVolumes () {
  local ACTION="${1:?}"
  local PREFIX="${2:?}"

  shift 2

  for i; do
    local VOLUME="$PREFIX_$i"

    echoComment "Performing $ACTION on the following docker volume $VOLUME"
    echoSeparator

    if [ "$ACTION" = 'rm' ]; then 
      docker image $ACTION -f $VOLUME
    else
      docker image $ACTION $VOLUME
    fi

    ACTION="$(changeCase "$ACTION" 'sentence')"

    echoSeparator
    echoComment "$ACTION performed on $VOLUME."
  done

  echoSeparator
  docker image ls
  echoSeparator
}