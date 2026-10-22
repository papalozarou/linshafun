#!/bin/sh

# ------------------------------------------------------------------------------
# Functions to check variables.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Checks if a variable name is valid. Returns 0 if the name contains only
# letters, digits and underscores, and doesn't start with a digit, returns 1
# otherwise. Takes one argument:
#
# 1. "$1" – the variable name, not its value, e.g. "DOCKER_DIR_PATH".
#
# Functions that pass a variable name to "eval" run it as part of a command, so 
# a name containing shell syntax, e.g. "X}; rm -rf ~", would be run. This check
# prevents that.
#
# N.B.
# "$1" is used rather than "${1:?}", as an empty name must return 1 rather
# than stop the script with an error.
# ------------------------------------------------------------------------------
checkIfValidVariableName () {
  local VAR_NAME="$1"

  case "$VAR_NAME" in
    ''|[0-9]*|*[!A-Za-z0-9_]*)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

# ------------------------------------------------------------------------------
# Verifies variables are set. Takes one or more arguments:
#
# 1. "$@" – one or more variable names to verify.
#
# The function prints an error for variables that are unset or empty, then 
# returns 1 if any were so the calling script can stop before changing anything,
# e.g.:
#
# verifyVariablesSet 'DOCKER_DIR_PATH' 'BACKUP_DIR_PATH' || exit 1
#
# "eval" must be used to indirectly reference each variable, the name of which 
# is stored within "$VAR_NAME", as per:
#
# - https://unix.stackexchange.com/a/41418
#
# N.B.
# Each name is checked with "checkIfValidVariableName" before it is passed to
# "eval", so shell syntax cannot be accidentally passed and run by "eval".
# ------------------------------------------------------------------------------
verifyVariablesSet () {
  local VAR_NAME
  local VAR_VALUE
  local STATUS=0

  for VAR_NAME in "$@"; do
    if ! checkIfValidVariableName "$VAR_NAME"; then
      printComment --error -- "$VAR_NAME is not a valid variable name."

      STATUS=1

      continue
    fi

    eval "VAR_VALUE=\${$VAR_NAME:-}"

    if [ -z "$VAR_VALUE" ]; then
      printComment --error -- "$VAR_NAME is not set."

      STATUS=1
    fi
  done

  return "$STATUS"
}
