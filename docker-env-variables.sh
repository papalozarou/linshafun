#!/bin/sh

# ------------------------------------------------------------------------------
# Functions for getting, reading and setting docker environment variables.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Asks the user if they want to re-set an existing docker environment variable. 
# Takes two arguments, one of which is mandatory:
# 
# 1. "${1:-"$DKR_ENV_FILE_PATH"}" – the environment file, including the
#    directory path and defaulting to "$DKR_ENV_FILE_PATH"; and
# 2. "${2:?}" – the existing variable.
# 
# If a user choses "y/Y" the variable is set via "setEnvVariable".
# 
# If the value is blank or missing, "(not set)" is shown as the current value.
# 
# If "$ENV_VALUE" names a host env variable, e.g. "$HOST_SUBDOMAIN", "eval" is
# used to indirectly reference the host env variable, using "case", as per:
# 
# - https://unix.stackexchange.com/a/41418
# - https://stackoverflow.com/a/229585
# - https://stackoverflow.com/a/19897118
# - https://www.shellscript.sh/case.html?cmdf=how+to+use+case+statement+sh
#
# N.B.
# The name after "$" is checked with "checkIfValidVariableName" before it is
# passed to "eval", so a value such as "$HOST_X; rm -rf ~" is shown as written
# rather than run.
# ------------------------------------------------------------------------------
changeDockerEnvVariable () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"
  local ENV_VAR="${2:?}"
  local ENV_VALUE="$(readDockerEnvVariable "$ENV_FILE_PATH" "$ENV_VAR")"
  local HOST_VAR_NAME="${ENV_VALUE#\$}"

  case "$ENV_VALUE" in
      '$HOST'*)
        checkIfValidVariableName "$HOST_VAR_NAME" && eval "ENV_VALUE=\${$HOST_VAR_NAME}"
        ;;
  esac

  printComment "The current value of $ENV_VAR is:"
  printSeparator
  printComment "${ENV_VALUE:-(not set)}"
  printSeparator

  promptForUserInput "Do you want to set a new value for $ENV_VAR (y/n)?" 'This may break existing setups if running these scripts again.'

  if ! getUserInputYN; then
    printComment "No changes to $ENV_VAR made."

    return 0
  fi

  if [ "$ENV_VAR" = "H_RTT_PORT" ]; then
    ENV_VALUE="$(generateAndCheckPort "ssh")"
  else
    promptForUserInput "What value do you require for $ENV_VAR?"
    ENV_VALUE="$(getUserInput)"
  fi

  setDockerEnvVariable "$ENV_FILE_PATH" "$ENV_VAR" "$ENV_VALUE"
}

# ------------------------------------------------------------------------------
# Checks for and sets multiple docker environment variables. Takes at least two 
# arguments:
# 
# 1. "${1:-"$DKR_ENV_FILE_PATH"}" – the environment file, including the
#    directory path and defaulting to "$DKR_ENV_FILE_PATH"; and
# 2. "$@" – one or more environment variables to set.
# 
# The function takes the first argument and stores it as the environment 
# variable file. It then shifts the argument position by 1, and loops through 
# each of the rest of the arguments. As per:
# 
# - https://unix.stackexchange.com/a/225951
# ------------------------------------------------------------------------------
checkAndSetDockerEnvVariables () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"
  local ENV_VAR

  shift

  for ENV_VAR in "$@"; do
    printComment "Checking to see if $ENV_VAR is set…"

    if checkIfDockerEnvVariableSet "$ENV_FILE_PATH" "$ENV_VAR"; then
      printComment "$ENV_VAR is set."
    else
      printComment "$ENV_VAR is not set." 'warning'
    fi

    changeDockerEnvVariable "$ENV_FILE_PATH" "$ENV_VAR"
  done
}

# ------------------------------------------------------------------------------
# Checks whether a docker environment variable has been set. Takes two 
# arguments, one of which is mandatory:
# 
# 1. "${1:-"$DKR_ENV_FILE_PATH"}" – the environment file, including the
#    directory path and defaulting to "$DKR_ENV_FILE_PATH"; and
# 2. "${2:?}" – the required variable.
# 
# Returns 0 if the variable is set, returns 1 if it is unset or is set to
# "${DKR_ENV: $VAR}".
# ------------------------------------------------------------------------------
checkIfDockerEnvVariableSet () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"
  local ENV_VAR="${2:?}"
  local ENV_VALUE="$(readDockerEnvVariable "$ENV_FILE_PATH" "$ENV_VAR")"

  [ -n "$ENV_VALUE" ] && [ "$ENV_VALUE" != "\${DKR_ENV: \$$ENV_VAR}" ]
}

# ------------------------------------------------------------------------------
# Compares an environment file value with a given value and updates the 
# environment value if requested. Takes two or more arguments:
# 
# 1. "${1:-"$DKR_ENV_FILE_PATH"}" – the environment file, including the
#    directory path and defaulting to "$DKR_ENV_FILE_PATH"; and
# 2. "$@" – the name(s) of the environment variable(s).
#
# The function takes the first argument and stores it as the environment 
# variable file. It then shifts the argument position by 1, and loops through 
# each of the rest of the arguments. Taken from:
# 
# - https://unix.stackexchange.com/a/225951
# 
# "eval" is used to indirectly reference a variable, the name of which is stored 
# within "$ENV_VAR", as per:
# 
# - https://unix.stackexchange.com/a/41418
# 
# If a name isn't a valid variable name, the function prints an error and
# carries on with the rest. It returns 1 if any name was invalid or any change
# failed.
#
# N.B.
# This comparison function expects the indirect referenced variable to already 
# have been set in the global scope of the script that calls this function.
#
# Each name is checked with "checkIfValidVariableName" before it is passed to
# "eval", so shell syntax cannot be accidentally passed and run by "eval".
# ------------------------------------------------------------------------------
compareAndUpdateDockerEnvVariables () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"
  local STATUS=0
  local ENV_VAR

  shift

  for ENV_VAR in "$@"; do
    if ! checkIfValidVariableName "$ENV_VAR"; then
      printComment "$ENV_VAR is not a valid variable name." 'error'

      STATUS=1

      continue
    fi

    local ENV_VALUE="$(readDockerEnvVariable "$ENV_FILE_PATH" "$ENV_VAR")"

    eval "local ENV_COMPARISON=\${$ENV_VAR}"

    printComment "Comparing the env variable for $ENV_VAR with the comparison value…"

    if compareDockerEnvVariableWithValue "$ENV_FILE_PATH" "$ENV_VAR" "$ENV_COMPARISON"; then
      printComment "The current value of $ENV_VAR is the same as the comparison value:"
      printSeparator
      printComment "Environment file value: $ENV_VALUE"
      printComment "Comparison value:       $ENV_COMPARISON"
      printSeparator
      printComment "No changes to $ENV_VAR made."
    else
      printComment "The current value of $ENV_VAR is different to the comparison value:" 'warning'
      printSeparator
      printComment "Environment file value: $ENV_VALUE" 'warning'
      printComment "Comparison value:       $ENV_COMPARISON" 'warning'
      printSeparator

      changeDockerEnvVariable "$ENV_FILE_PATH" "$ENV_VAR" || STATUS=1
    fi
  done

  return "$STATUS"
}

# ------------------------------------------------------------------------------
# Compares a docker env variable with a given value. Takes three arguments, two
# of which are mandatory:
# 
# 1. "${1:-"$DKR_ENV_FILE_PATH"}" – the environment file, including the
#    directory path and defaulting to "$DKR_ENV_FILE_PATH";
# 2. "${2:?}" – an environment variable to check; and
# 3. "${3:?}" – a value to compare against.
# 
# Returns 0 if the variable matches the comparison value, returns 1 otherwise.
# ------------------------------------------------------------------------------
compareDockerEnvVariableWithValue () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"
  local ENV_VAR="${2:?}"
  local ENV_COMPARISON="${3:?}"
  local ENV_VALUE="$(grep -m 1 "^$ENV_VAR=" "$ENV_FILE_PATH" | cut -d'=' -f2-)"

  [ "$ENV_VALUE" = "$ENV_COMPARISON" ]
}

# ------------------------------------------------------------------------------
# Reads an environment variable from a file. Takes two arguments, one of
# which is mandatory:
# 
# 1. "${1:-"$DKR_ENV_FILE_PATH"}" – the environment file, including the
#    directory path and defaulting to "$DKR_ENV_FILE_PATH"; and
# 2. "${2:?}" – an environment variable to check.
# 
# The variable and value are read from the file with "grep" as a single string, 
# then piped to "cut", which uses the equals sign as a field delimter to return 
# the second field onwards, i.e. the whole value, including any equals signs
# within it. As per:
# 
# - https://unix.stackexchange.com/a/312281
# 
# N.B.
# "grep" is passed the flag "-m 1" to match only the first instance of the 
# variable. As per:
# 
# - https://stackoverflow.com/a/14093511
# ------------------------------------------------------------------------------
readDockerEnvVariable () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"
  local ENV_VAR="${2:?}"
  local ENV_VALUE="$(grep -m 1 "^$ENV_VAR=" "$ENV_FILE_PATH" | cut -d'=' -f2-)"

  echo "$ENV_VALUE"
}

# ------------------------------------------------------------------------------
# Substitutes instances of "${DKR_ENV: $ENV_VAR}" with correct values. 
# Takes three mandatory arguments:
# 
# 1. "${1:?}" – the file containing the environment variable, including the 
#    directory path;
# 2. "${2:?}" – an environment variable to replace; and
# 3. "${3:?}" – the value of the variable.
# 
# The "sed" delimiter is "|" in this instance as both "/" and "@" will be
# returned as part of string hashing or present in email addresses.
#
# "\", "&" and "|" are escaped in the value, as "sed" treats them as special
# characters in the replacement, e.g. "&" inserts the matched placeholder.
# 
# If "sed" fails, e.g. the file doesn't exist, the function prints an error and
# returns 1.
#
# N.B.
# This only replaces the above string, and is used on configuration files, not 
# ".env" files.
# ------------------------------------------------------------------------------
replaceDockerEnvPlaceholderVariable () {
  local ENV_FILE_PATH="${1:?}"
  local ENV_VAR='${DKR_ENV: '"${2:?}"'}'
  local ENV_VALUE="${3:?}"
  local ESCAPED_VALUE="$(printf '%s\n' "$ENV_VALUE" | sed 's/[\\&|]/\\&/g')"

  printComment "Replacing placholder $ENV_VAR with value $ENV_VALUE, in:"
  printComment "$ENV_FILE_PATH"
  printSeparator
  grep "$ENV_VAR" "$ENV_FILE_PATH"
  printSeparator

  if ! sed -i 's|'"$ENV_VAR"'|'"$ESCAPED_VALUE"'|g' "$ENV_FILE_PATH"; then
    printComment "Failed to replace $ENV_VAR in $ENV_FILE_PATH." 'error'

    return 1
  fi

  printComment 'Checking variables have been replaced…'
  printSeparator
  grep "$ENV_VALUE" "$ENV_FILE_PATH"
  printSeparator
  printComment "Placeholder variable replaced."
}

# ------------------------------------------------------------------------------
# Sets an environment variable in a given environment file. Takes three 
# arguments, two of which are mandatory:
#
# 1. "${1:-"$DKR_ENV_FILE_PATH"}" – the environment file, including the
#    directory path and defaulting to "$DKR_ENV_FILE_PATH";
# 2. "${2:?}" – the variable name; and
# 3. "${3:?}" – the variable value.
# 
# The function uses "sed" to replace the variable with the value in the 
# specified document. As per:
# 
# - https://stackoverflow.com/a/11245501
# 
# If no line starts with "$ENV_VAR=", or "sed" fails, the function prints an
# error and returns 1. The variable is never added, only changed.
#
# N.B.
# It's necessary to use single and double quotes, as well as escaped characters, 
# to enable "sed" to parse the variables where required.
#
# "\" is escaped in the value, as "sed" removes it from the replacement line,
# e.g. "a\b" would be written as "ab".
#
# The variable is checked for before "sed" runs, as "sed" succeeds without
# changing anything when no line matches.
# ------------------------------------------------------------------------------
setDockerEnvVariable () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"
  local ENV_VAR="${2:?}"
  local ENV_VALUE="${3:?}"
  local ESCAPED_VALUE="$(printf '%s\n' "$ENV_VALUE" | sed 's/\\/\\\\/g')"

  printComment "Setting $ENV_VAR to $ENV_VALUE in:"
  printComment "$ENV_FILE_PATH"

  if ! grep -q "^$ENV_VAR=" "$ENV_FILE_PATH"; then
    printComment "Failed to set $ENV_VAR, as it was not found in $ENV_FILE_PATH." 'error'

    return 1
  fi

  if ! sed -i '/^'"$ENV_VAR"='/c\\'"$ENV_VAR=$ESCAPED_VALUE" "$ENV_FILE_PATH"; then
    printComment "Failed to set $ENV_VAR in $ENV_FILE_PATH." 'error'

    return 1
  fi

  printSeparator
  grep "$ENV_VALUE" "$ENV_FILE_PATH"
  printSeparator
  printComment 'Variable updated.'
}