#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for manipulating docker volumes.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Lists the contents of docker volumes. Takes one or more arguments
# 
# 1. "${1:?}" – the voolume prefix, usually the compose "name" attribute; and
# 2. "$@" – one or more volumes to be listed, excluding prefix.
#
# N.B.
# The prefix is converted to lower case and an underscore is added to the end to
# enable "$PREFIX$VOLUME" to produce "prefix_volume".
#-------------------------------------------------------------------------------
listDockerVolumeContents () {
  local PREFIX="$(changeCase "${1:?}" 'lower')_"
  
  for VOLUME in "$@"; do
    local VOLUME="$PREFIX$VOLUME"

    printComment 'Listing contents of the following docker volume:'
    printComment "$VOLUME"

    printSeparator
    docker run --rm -i -v="$VOLUME":/tmp/myvolume busybox ls -lna -R /tmp/myvolume
    printSeparator
  done
}

#-------------------------------------------------------------------------------
# Manages docker volumes. Takes at least two mandatory arguments:
#
# 1. "${1:?}" – the action to perform; 
# 2. "${2:?}" – the prefix for the volumes; and
# 2. "$@" – one ore more volumes, excluding prefix.
#
# N.B.
# The prefix is converted to lower case and an underscore is added to the end to
# enable "$PREFIX$VOLUME" to produce "prefix_volume".
#-------------------------------------------------------------------------------
manageDockerVolumes () {
  local ACTION="${1:?}"
  local PREFIX="$(changeCase "${2:?}" 'lower')_"

  printComment "$ACTION and $PREFIX"

  shift 2

  for VOLUME in "$@"; do
    local VOLUME="$PREFIX$VOLUME"

    printComment "Performing $ACTION on the following docker volume:"
    printComment "$VOLUME"
    printSeparator

    if [ "$ACTION" = 'rm' ]; then 
      docker volume "$ACTION" -f "$VOLUME"
    else
      docker volume "$ACTION" "$VOLUME"
    fi

    printSeparator
    ACTION="$(changeCase "$ACTION" 'sentence')"
    printComment "$ACTION performed on $VOLUME."
  done
}