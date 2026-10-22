#!/bin/sh

# ------------------------------------------------------------------------------
# Functions to check, install and remove packages.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Checks whether a given package is already installed. Takes one mandatory
# argument:
# 
# 1. "${1:?}" – the package to be checked. 
# 
# Returns 1 if the package is not installed, returns 0 if the package is 
# installed. The check reads the package's status word from "dpkg-query", and
# only "installed" counts, so a package that was removed but left its config
# files behind reads as not installed. As per:
#
# - https://man7.org/linux/man-pages/man1/dpkg-query.1.html
# 
# N.B.
# This function explicitly checks a single package to allow for a simple 0 or 1
# status.
#
# The argument must be a package name, not a command name, e.g. "docker-ce", not
# "docker". A package that "dpkg" doesn't know about reads as not installed.
# ------------------------------------------------------------------------------
checkForPackage () {
  local PACKAGE="${1:?}"
  local STATUS="$(dpkg-query -W -f='${db:Status-Status}' "$PACKAGE" 2>/dev/null)"

  [ "$STATUS" = 'installed' ]
}

# ------------------------------------------------------------------------------
# Checks if one or more packages are installed and if not the packages are 
# installed. Takes one or more mandatory arguments:
# 
# 1. "$@" – the package or packages to be installed.
# ------------------------------------------------------------------------------
checkForPackagesAndInstall () {
  local PACKAGE

  printComment 'Starting installation of the following packages:'
  printComment -- "$*"

  for PACKAGE in "$@"; do
    printComment "Checking to see if $PACKAGE is installed…"

    if checkForPackage "$PACKAGE"; then
      printComment "You have already installed $PACKAGE."
    else
      printComment --warning "You need to install $PACKAGE."
      managePackages "install" "$PACKAGE"
    fi
  done
}

# ------------------------------------------------------------------------------
# Checks if one or more packages are installed and if they are the packages is 
# removed. Takes one or more mandatory arguments:
# 
# 1. "$@" – the package or packages to be removed.
# ------------------------------------------------------------------------------
checkForPackagesAndRemove () {
  local PACKAGE

  printComment 'Starting removal of the following packages:'
  printComment -- "$*"

  for PACKAGE in "$@"; do
    printComment "Checking to see if $PACKAGE is installed…"

    if checkForPackage "$PACKAGE"; then
      printComment --warning "You need to remove $PACKAGE."
      managePackages "remove" "$PACKAGE"
    else
      printComment "You have already removed $PACKAGE."
    fi
  done
}

# ------------------------------------------------------------------------------
# Installs or removes a given package. Takes at least two or more arguments:
# 
# 1. "${1:?}" – the action to be taken, either "install" or "remove"
# 2. "$@" – one or more packages to install or remove.
# 
# The function tests to see if the an accepted value has been passed as the
# first argument then stores it as the action to be taken. It then shifts the 
# argument position by 1, and loops through each of the rest of the arguments. 
# As per:
# 
# - https://unix.stackexchange.com/a/225951
#
# If the first argument isn't "install" or "remove", the function prints an
# error and returns 1.
#
# If "apt" fails for a package, the function prints an error, carries on with
# the remaining packages, and returns 1.
# ------------------------------------------------------------------------------
managePackages () {
  local ACTION="${1:?}"
  local STATUS=0
  local PACKAGE

  if [ "$ACTION" != 'install' ] && [ "$ACTION" != 'remove' ]; then
    printComment --error "Unknown action \"$ACTION\". Use \"install\" or \"remove\"."

    return 1
  fi

  shift

  for PACKAGE; do
    printComment "Performing $ACTION for $PACKAGE."
    printSeparator

    if ! apt "$ACTION" "$PACKAGE" -y; then
      printSeparator
      printComment --error "Failed to $ACTION $PACKAGE."
      STATUS=1

      continue
    fi

    printSeparator
    printComment "Completed $ACTION for $PACKAGE"
  done

  return "$STATUS"
}

# ------------------------------------------------------------------------------
# Updates and upgrades installed packages. Takes no arguments.
#
# If "apt update" or "apt upgrade" fails, the function prints an error and
# returns 1. "apt upgrade" isn't run if "apt update" fails.
# ------------------------------------------------------------------------------
updateAndUpgradePackages () {
  local PKGCACHE_PATH='/var/cache/apt/pkgcache.bin'
  local CURRENT_TIME="$(date +%s)"
  local LAST_UPDATE="$(stat -c %Y "$PKGCACHE_PATH" 2>/dev/null || echo 0)"
  local TIME_DIFF=$((CURRENT_TIME - LAST_UPDATE))
  local STATUS=0

  if [ "$TIME_DIFF" -ge 86400 ] || [ "$LAST_UPDATE" -eq 0 ]; then
    printComment 'Updating and upgrading packages…'
    printSeparator
    { apt update && apt upgrade -y; } || STATUS=1
    printSeparator
  else
    printComment 'Packages were updated less than 24 hours ago. Skipping update and upgrade.'

    return 0
  fi

  if [ "$STATUS" -ne 0 ]; then
    printComment --error 'Failed to update and upgrade packages.'

    return 1
  fi

  printComment 'Packages updated and upgraded.'
}