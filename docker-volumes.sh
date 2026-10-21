#!/bin/sh

# ------------------------------------------------------------------------------
# Functions for manipulating docker volumes.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Lists the contents of docker volumes. Takes two or more arguments:
# 
# 1. "${1:?}" – the volume prefix, usually the compose "name" attribute; and
# 2. "$@" – one or more volumes to be listed, excluding prefix.
#
# N.B.
# The prefix is converted to lower case and an underscore is added to the end to
# enable "$PREFIX$VOLUME" to produce "prefix_volume".
# ------------------------------------------------------------------------------
listDockerVolumeContents () {
  local PREFIX="$(changeCase "${1:?}" 'lower')_"
  local VOLUME_NAME
  local VOLUME
  
  for VOLUME_NAME in "$@"; do
    VOLUME="$PREFIX$VOLUME_NAME"

    printComment 'Listing contents of the following docker volume:'
    printComment -- "$VOLUME"

    printSeparator
    docker run --rm -i -v="$VOLUME":/tmp/myvolume busybox ls -lna -R /tmp/myvolume
    printSeparator
  done
}

# ------------------------------------------------------------------------------
# Manages docker volumes. Takes at least three mandatory arguments:
#
# 1. "${1:?}" – the action to perform; 
# 2. "${2:?}" – the prefix for the volumes; and
# 3. "$@" – one or more volumes, excluding prefix.
#
# N.B.
# The prefix is converted to lower case and an underscore is added to the end to
# enable "$PREFIX$VOLUME" to produce "prefix_volume".
#
# If "docker volume" fails for a volume, the function prints an error, carries
# on with the remaining volumes, and returns 1.
#
# The action is converted to sentence case once, into "ACTION_SENTENCE", for
# the output. "ACTION" is left as passed, as "docker volume" needs it in lower
# case for every volume.
# ------------------------------------------------------------------------------
manageDockerVolumes () {
  local ACTION="${1:?}"
  local PREFIX="$(changeCase "${2:?}" 'lower')_"
  local ACTION_SENTENCE="$(changeCase "$ACTION" 'sentence')"
  local VOLUME_STATUS=0
  local STATUS=0
  local VOLUME_NAME
  local VOLUME

  shift 2

  for VOLUME_NAME in "$@"; do
    VOLUME="$PREFIX$VOLUME_NAME"
    VOLUME_STATUS=0

    printComment "Performing $ACTION on the following docker volume:"
    printComment -- "$VOLUME"
    printSeparator

    if [ "$ACTION" = 'rm' ]; then 
      docker volume "$ACTION" -f "$VOLUME" || VOLUME_STATUS="$?"
    else
      docker volume "$ACTION" "$VOLUME" || VOLUME_STATUS="$?"
    fi

    printSeparator

    if [ "$VOLUME_STATUS" -ne 0 ]; then
      printComment --error -- "$ACTION_SENTENCE failed on $VOLUME."
      STATUS=1

      continue
    fi

    printComment -- "$ACTION_SENTENCE performed on $VOLUME."
  done

  return "$STATUS"
}