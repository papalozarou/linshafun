#!/bin/sh

# ------------------------------------------------------------------------------
# Functions for adding to a user, or root, crontab.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Adds a script, on a schedule, to a given user's crontab, via a snippet in 
# "/etc/cron.d". Takes five arguments:
#
# 1. "--no-log" – an optional flag, passed first, to turn off log output to a
#    file in the user's home directory;
# 2. "${1:-"root"}" – a username, defaulting to "root";
# 3. "${2:-"$CRON_SCRIPT_PATH"}" – the command to run or the file path, 
#    including directory path, defaulting to the global variable
#    "$CRON_SCRIPT_PATH";
# 4. "${3:-"$CRON_SCHEDULE"}" – the cron schedule, in "* * * * *" format, 
#    defaulting to the global variable "$CRON_SCHEDULE"; and
# 5. "${4:-"$CRON_SNIPPET_NAME"}" – the snippet name to be placed in 
#    "/etc/cron.d", defaulting to the global variable "$CRON_SNIPPET_NAME".
# 
# N.B.
# If using the global variables they must be assigned first using their 
# respective functions:
# 
# - "getCronFilenames"; and
# - "getCronSchedule".
# 
# If the snippet can't be written to "/etc/cron.d", the function prints an
# error and returns 1. It also returns 1 with an error if an option is unknown
# or comes after the other arguments.
# ------------------------------------------------------------------------------
addScriptToCron () {
  local NO_LOG_TF=false
  local OPTION_COUNT=0
  local CRON_USER
  local CMD_OR_SCRIPT_PATH
  local SCHEDULE
  local SNIPPET_NAME
  local SNIPPET_PATH
  local CRON_LINE

  readOptions 'no-log=NO_LOG_TF' "$@" || return 1
  shift "$OPTION_COUNT"

  CRON_USER="${1:-"root"}"
  CMD_OR_SCRIPT_PATH="${2:-"$CRON_SCRIPT_PATH"}"
  SCHEDULE="${3:-"$CRON_SCHEDULE"}"
  SNIPPET_NAME="${4:-"$CRON_SNIPPET_NAME"}"
  SNIPPET_PATH="/etc/cron.d/$SNIPPET_NAME"
  CRON_LINE="$SCHEDULE $CRON_USER $CMD_OR_SCRIPT_PATH"

  printComment 'Adding to the system crontab, as a snippet in "/etc/cron.d".'

  if [ "$NO_LOG_TF" = false ]; then
    CRON_LINE="$CRON_LINE >> $USER_LOG_DIR_PATH/$SNIPPET_NAME.log 2>&1"
  fi

  if ! printf '%s\n' "$CRON_LINE" > "$SNIPPET_PATH"; then
    printComment --error 'An error occurred when creating the snippet.'

    return 1
  fi

  printComment 'Checking contents of snippet…'
  printSeparator
  cat "$SNIPPET_PATH"
  printSeparator
  printComment 'Script added to cron, using a snippet in "/etc/cron.d".'
}

# ------------------------------------------------------------------------------
# Gets the script filename, then generates the snippet name, for the cronjob. 
# These are placed in global variables, "$CRON_SCRIPT_NAME",
# "$CRON_SNIPPET_NAME" and "$CRON_SCRIPT_PATH", for use in other functions.
# Takes no arguments.
# ------------------------------------------------------------------------------
getCronFilenames () {
  promptForUserInput 'What is the name of your script? This will also be the name of the snippet placed in "/etc/cron.d". You do not need to include the file extension ".sh"' 'It is assumed the script is placed in your home directory. If you wish to place it elsewhere do so, however you will need to update the generated snippet to point to this new location.'
  CRON_SCRIPT_NAME="$(getUserInput)"

  CRON_SNIPPET_NAME="$CRON_SCRIPT_NAME"
  CRON_SCRIPT_PATH="$USER_DIR_PATH/$CRON_SCRIPT_NAME.sh"
}

# ------------------------------------------------------------------------------
# Gets a schedule for the cronjob. This is placed in a global variable, 
# "$CRON_SCHEDULE", for use in other functions. Takes no arguments.
# ------------------------------------------------------------------------------
getCronSchedule () {
  promptForUserInput 'What schedule do you want this script to run on?' 'The format of the schedule should be five values separated by spaces, i.e. "x x x x x". You can use https://crontab.guru to help create the correct schedule.'
  CRON_SCHEDULE="$(getUserInput)"
}

