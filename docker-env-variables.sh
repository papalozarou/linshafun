#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for getting, reading and setting docker environment variables.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Asks the user if they want to re-set an existing docker environment variable. 
# Takes two mandatory arguments:
# 
# 1. "${1:?}" – the environment file, including the directory path and
#    defaulting to "$DKR_ENV_FILE_PATH"; and
# 2. "${2:?}" – the existing variable.
# 
# If a user choses "y/Y" the variable is set via "setEnvVariable".
# 
# If "$ENV_VALUE" is "$HOST_SUBDOMAIN", "eval" is used to indirectly reference 
# the host env variable stored in "$HOST_SUBDOMAIN", using "case", as per:
# 
# - https://unix.stackexchange.com/a/41418
# - https://stackoverflow.com/a/229585
# - https://stackoverflow.com/a/19897118
# - https://www.shellscript.sh/case.html?cmdf=how+to+use+case+statement+sh
#-------------------------------------------------------------------------------
changeDockerEnvVariable () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"
  local ENV_VAR="${2:?}"
  local ENV_VALUE="$(readDockerEnvVariable "$ENV_FILE_PATH" "$ENV_VAR")"

  case "$ENV_VALUE" in
      '$HOST'*)
        eval "ENV_VALUE=$ENV_VALUE"
        ;;
  esac

  printComment "The current value of $ENV_VAR is:"
  printSeparator
  printComment "$ENV_VALUE"
  printSeparator

  promptForUserInput "Do you want to set a new value for $ENV_VAR (y/n)?" 'This may break existing setups if running these scripts again.'
  ENV_VAR_SET_YN="$(getUserInputYN)"

  if [ "$ENV_VAR_SET_YN" = true ] && [ "$ENV_VAR" = "H_RTT_PORT" ]; then
    ENV_VALUE="$(generateAndCheckPort "ssh")"
  elif [ "$ENV_VAR_SET_YN" = true ]; then
    promptForUserInput "What value do you require for $ENV_VAR?"
    ENV_VALUE="$(getUserInput)"
  fi

  if [ "$ENV_VAR_SET_YN" = true ]; then
    setDockerEnvVariable "$ENV_FILE_PATH" "$ENV_VAR" "$ENV_VALUE"
  else
    printComment "No changes to $ENV_VAR made."
  fi
}

#-------------------------------------------------------------------------------
# Checks for and sets multiple docker environment variables. Takes at least two 
# arguments:
# 
# 1. "${1:?}" – the environment file, including the directory path and
#    defaulting to "$DKR_ENV_FILE_PATH"; and
# 2. "$i" – one or more environment variables to set.
# 
# The function takes the first argument and stores it as the environment 
# variable file. It then shifts the argument position by 1, and loops through 
# each of the rest of the arguments. As per:
# 
# - https://unix.stackexchange.com/a/225951
#-------------------------------------------------------------------------------
checkAndSetDockerEnvVariables () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"

  shift

  for ENV_VAR in "$@"; do
    local ENV_VAR_TF="$(checkIfDockerEnvVariableSet "$ENV_FILE_PATH" "$ENV_VAR")"

    printCheckResult "to see if $ENV_VAR is set" "$ENV_VAR_TF"

    changeDockerEnvVariable "$ENV_FILE_PATH" "$ENV_VAR"
  done
}

#-------------------------------------------------------------------------------
# Checks whether a docker environment variable has been set. Takes two mandatory 
# arguments:
# 
# 1. "${1:?}" – the environment file, including the directory path and
#    defaulting to "$DKR_ENV_FILE_PATH"; and
# 2. "${2:?}" – the required variable.
# 
# Returns true if the variable is set, returns false if it is unset or is set to
# "${DKR_ENV: $VAR}".
#-------------------------------------------------------------------------------
checkIfDockerEnvVariableSet () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"
  local ENV_VAR="${2:?}"
  local ENV_VALUE="$(readDockerEnvVariable "$ENV_FILE_PATH" "$ENV_VAR")"

  if [ -z "$ENV_VALUE" ] || [ "$ENV_VALUE" = "\${DKR_ENV: \$$ENV_VAR}" ]; then
    echo false
  else
    echo true
  fi
}

#-------------------------------------------------------------------------------
# Compares an environment file value with a given value and updates the 
# environment value if requested. Takes two or more mandatory arguements:
# 
# 1. "${1:?}" – the environment file, including the directory path and
#    defaulting to "$DKR_ENV_FILE_PATH"; and
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
# N.B.
# This comparison function expects the indirect referenced variable to already 
# have been set in the global scope of the script that calls this function.
#-------------------------------------------------------------------------------
compareAndUpdateDockerEnvVariables () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"

  shift

  for ENV_VAR in "$@"; do
    local ENV_VALUE="$(readDockerEnvVariable "$ENV_FILE_PATH" "$ENV_VAR")"

    eval "local ENV_COMPARISON=\${$ENV_VAR}"

    local ENV_NEWER_TF="$(compareDockerEnvVariableWithValue "$ENV_FILE_PATH" "$ENV_VAR" "$ENV_COMPARISON")"

    printComment "Comparing the env variable for $ENV_VAR with the comparison value…"

    if [ "$ENV_NEWER_TF" = true ]; then
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

      changeDockerEnvVariable "$ENV_FILE_PATH" "$ENV_VAR"
    fi
  done
}

#-------------------------------------------------------------------------------
# Compares a docker env variable with a given value. Takes three mandatory 
# arguments:
# 
# 1. "${1:?}" – the environment file, including the directory path and
#    defaulting to "$DKR_ENV_FILE_PATH"; and
# 2. "${2:?}" - an environment variable to check; and
# 3. "${3:?}" - a value to compare against.
# 
# Returns true if the variable matches the comparison value, returns false 
# otherwise.
#-------------------------------------------------------------------------------
compareDockerEnvVariableWithValue () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"
  local ENV_VAR="${2:?}"
  local ENV_COMPARISON="${3:?}"
  local ENV_VALUE="$(grep -m 1 "$ENV_VAR=" "$ENV_FILE_PATH" | cut -d'=' -f2)"

  if [ "$ENV_VALUE" = "$ENV_COMPARISON" ]; then
    echo true
  else
    echo false
  fi
}

#-------------------------------------------------------------------------------
# Reads an environment variable from a file. Takes two mandatory arguments:
# 
# 1. "${1:?}" – the environment file, including the directory path and
#    defaulting to "$DKR_ENV_FILE_PATH"; and
# 2. "${2:?}" - an environment variable to check.
# 
# The variable and value are read from the file with "grep" as a single string, 
# then piped to "cut", which uses the equals sign as a field delimter to return 
# the second field, i.e. the value. As per:
# 
# - https://unix.stackexchange.com/a/312281
# 
# N.B.
# "grep" is passed the flag "-m 1" to match only the first instance of the 
# variable. As per:
# 
# - https://stackoverflow.com/a/14093511
#-------------------------------------------------------------------------------
readDockerEnvVariable () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"
  local ENV_VAR="${2:?}"
  local ENV_VALUE="$(grep -m 1 "$ENV_VAR=" "$ENV_FILE_PATH" | cut -d'=' -f2)"

  echo "$ENV_VALUE"
}

#-------------------------------------------------------------------------------
# Substitutes instances of "${DKR_ENV: $ENV_VAR}" with correct values. 
# Takes three mandatory arguments:
# 
# 1. "${1:?}" - the file containing the environment variable, including the 
#    directory path;
# 2. "${2:?}" - an environment variable to replace; and
# 3. "${3:?}" - the value of the variable.
# 
# The "sed" delimiter is "|" in this instance as both "/" and "@" will be
# returned as part of string hashing or present in email addresses.
# 
# N.B.
# This only replaces the above string, and is used on configuration files, not 
# ".env" files.
#-------------------------------------------------------------------------------
replaceDockerEnvPlaceholderVariable () {
  local ENV_FILE_PATH="${1:?}"
  local ENV_VAR='${DKR_ENV: '"${2:?}"'}'
  local ENV_VALUE="${3:?}"

  printComment "Replacing placholder $ENV_VAR with value $ENV_VALUE, in:"
  printComment "$ENV_FILE_PATH"
  printSeparator
  grep "$ENV_VAR" "$ENV_FILE_PATH"
  printSeparator

  sed -i 's|'"$ENV_VAR"'|'"$ENV_VALUE"'|g' "$ENV_FILE_PATH"

  printComment 'Checking variables have been replaced…'
  printSeparator
  grep "$ENV_VALUE" "$ENV_FILE_PATH"
  printSeparator
  printComment "Placeholder variable replaced."
}

#-------------------------------------------------------------------------------
# Sets an environment variable in a given environment file. Takes three 
# mandatory arguments:
#
# 1. "${1:?}" – the environment file, including the directory path and
#    defaulting to "$DKR_ENV_FILE_PATH";
# 2. "{2:?}" - the variable name; and
# 3. "{3:?}" - the variable value.
# 
# The function uses "sed" to replace the variable with the value in the 
# specified document. As per:
# 
# - https://stackoverflow.com/a/11245501
# 
# N.B.
# It's necessary to use single and double quotes, as well as escaped characters, 
# to enable "sed" to parse the variables where required.
#-------------------------------------------------------------------------------
setDockerEnvVariable () {
  local ENV_FILE_PATH="${1:-"$DKR_ENV_FILE_PATH"}"
  local ENV_VAR="${2:?}"
  local ENV_VALUE="${3:?}"

  printComment "Setting $ENV_VAR to $ENV_VALUE in:"
  printComment "$ENV_FILE_PATH"
  sed -i '/'"$ENV_VAR"='/c\\'"$ENV_VAR=$ENV_VALUE" "$ENV_FILE_PATH"
  printSeparator
  grep "$ENV_VALUE" "$ENV_FILE_PATH"
  printSeparator
  printComment 'Variable updated.'
}