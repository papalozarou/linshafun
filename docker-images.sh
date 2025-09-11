#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for manipulating docker images.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Creates one or more images. Takes at least two or more arguments:
# 
# 1. "${1:?}" - the compose file, including directory path and defaulting to 
#    "$DKR_COMPOSE_FILE_PATH"; and
# 2. "$@" – one or more images to be built.
# 
# The function takes the first argument and stores it as the compose file. It 
# then shifts the argument position by 1, and loops through each of the rest of
# the arguments. As per:
# 
# - https://unix.stackexchange.com/a/225951
#-------------------------------------------------------------------------------
buildDockerImages () {
  local COMPOSE_FILE_PATH="${1:-"$DKR_COMPOSE_FILE_PATH"}"

  shift

  for IMAGE in "$@"; do
    printComment "Building $IMAGE."
    printSeparator
    controlDockerService "$COMPOSE_FILE_PATH" "build" "$IMAGE" "--no-cache"
    printSeparator
    printComment 'Assuming there are no errors above, the image was built.' 'warning'
  done
}

#-------------------------------------------------------------------------------
# Lists images. Takes one mandatory argument:
#
# 1. "${1:?}" - the compose file, including directory path and defaulting to 
#    "$DKR_COMPOSE_FILE_PATH".
#-------------------------------------------------------------------------------
listDockerImages () {
  local COMPOSE_FILE_PATH="${1:-"$DKR_COMPOSE_FILE_PATH"}"

  printComment 'Listing docker images.'
  printSeparator
  docker compose -f "$COMPOSE_FILE_PATH" images
  printSeparator
}

#-------------------------------------------------------------------------------
# Removes one or more images. Takes at least one or more arguments:
# 
# 1. "$@" - one or more images to be removed.
#-------------------------------------------------------------------------------
removeDockerImages () {
  for IMAGE in "$@"; do
    printComment 'Removing the following docker image:'
    printComment "$IMAGE"
    printSeparator
    docker image rm "$IMAGE"
    printSeparator
  done
}