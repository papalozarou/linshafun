#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for manipulating docker images.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Creates one or more images. Takes at least two or more arguments:
# 
# 1. "${1:?}" - the compose file, including directory path; and
# 2. "$i" – one or more images to be built.
# 
# The function takes the first argument and stores it as the compose file. It 
# then shifts the argument position by 1, and loops through each of the rest of
# the arguments. As per:
# 
# - https://unix.stackexchange.com/a/225951
#-------------------------------------------------------------------------------
buildDockerImages () {
  local COMPOSE_FILE="${1:?}"

  shift

  for i; do
    printComment "Building $i."
    printSeparator
    controlDockerService "$COMPOSE_FILE" "build" "$i" "--no-cache"
    printSeparator
    printComment 'Assuming there are no errors above, the image was built.'
  done
}

#-------------------------------------------------------------------------------
# Lists images.
#-------------------------------------------------------------------------------
listDockerImages () {
  printComment 'Listing docker images.'
  printSeparator
  docker compose -f "$DOCKER_COMPOSE_FILE" images
  printSeparator
}

#-------------------------------------------------------------------------------
# Removes one or more images. Takes at least one or more arguments:
# 
# 1. "$@" - the image or images to be removed.
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