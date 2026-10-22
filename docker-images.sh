#!/bin/sh

# ------------------------------------------------------------------------------
# Functions for manipulating docker images.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Creates one or more images. Takes at least two or more arguments:
# 
# 1. "${1:-"$DKR_COMPOSE_FILE_PATH"}" – the compose file, including directory 
#    path and defaulting to "$DKR_COMPOSE_FILE_PATH"; and
# 2. "$@" – one or more images to be built.
#
# The shell stops the script if no images are passed, or if any are empty.
# 
# The function takes the first argument and stores it as the compose file. It 
# then shifts the argument position by 1, and loops through each of the rest of
# the arguments. As per:
# 
# - https://unix.stackexchange.com/a/225951
#
# If an image fails to build, "controlDockerService" prints the error. The
# function carries on with the remaining images, and returns 1.
# ------------------------------------------------------------------------------
buildDockerImages () {
  local COMPOSE_FILE_PATH="${1:-"$DKR_COMPOSE_FILE_PATH"}"
  local STATUS=0
  local IMAGE

  shift

  : "${1:?}"

  for IMAGE in "$@"; do
    : "${IMAGE:?}"
  done

  for IMAGE in "$@"; do
    printComment "Building $IMAGE."
    printSeparator
    controlDockerService "$COMPOSE_FILE_PATH" "build" "$IMAGE" "--no-cache" || STATUS=1
    printSeparator
  done

  return "$STATUS"
}

# ------------------------------------------------------------------------------
# Lists images. Takes one argument:
#
# 1. "${1:-"$DKR_COMPOSE_FILE_PATH"}" – the compose file, including directory 
#    path and defaulting to "$DKR_COMPOSE_FILE_PATH".
# ------------------------------------------------------------------------------
listDockerImages () {
  local COMPOSE_FILE_PATH="${1:-"$DKR_COMPOSE_FILE_PATH"}"

  printComment 'Listing docker images.'
  printSeparator
  docker compose -f "$COMPOSE_FILE_PATH" images
  printSeparator
}

# ------------------------------------------------------------------------------
# Removes one or more images. Takes at least one or more arguments:
# 
# 1. "$@" – one or more images to be removed.
#
# The shell stops the script if no images are passed, or if any are empty.
# ------------------------------------------------------------------------------
removeDockerImages () {
  local IMAGE

  : "${1:?}"

  for IMAGE in "$@"; do
    : "${IMAGE:?}"
  done

  for IMAGE in "$@"; do
    printComment 'Removing the following docker image:'
    printComment -- "$IMAGE"
    printSeparator
    docker image rm "$IMAGE"
    printSeparator
  done
}