#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for adding to a user, or root, crontab.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds a script, on a schedule, to a given user's crontab, via a snipper in 
# "/etc/cron.d". Takes four mandatory arguments:
#
# 1. "${1:?}" – a username, defaulting to "root";
# 2. "${2:?}" – the command to run or the file path, including directory path, 
#    defaulting to the global variable "$CRON_SCRIPT_NAME";
# 3. "${3:?}" – the cron schedule, in "* * * * *" format, defaulting to the 
#    global variable "$CRON_SCHEDULE";
# 4. "${4:?}" – the snippet name to be placed in "/etc/cron.d", defaulting to 
#    the global variable "$CRON_SNIPPET_NAME"; and
# 5. "${5:?}" – an optional flag to enable log output to a file in the user's 
#    home directory, defaulting to "true".
# 
# N.B.
# If using the global variables they must be assigned first using their 
# respective functions:
# 
# - "getCronFilenames"; and
# - "getCronSchedule".
#-------------------------------------------------------------------------------
addScriptToCron () {
  local USER="${1:-"root"}"
  local CMD_OR_SCRIPT_PATH="${2:-"$CRON_SCRIPT_PATH"}"
  local SCHEDULE="${3:-"$CRON_SCHEDULE"}"
  local SNIPPET_NAME="${4:-"$CRON_SNIPPET_NAME"}"
  local LOG_TF="${5:-true}"
  local SNIPPET_PATH="/etc/cron.d/$SNIPPET_NAME"
  local SCRIPT_LOG_PATH="$USER_DIR_PATH/log/$SNIPPET_NAME.log"

  printComment 'Adding to the system crontab, as a snippet in "/etc/cron.d".'

  if [ "$LOG_ENABLED" = true ]; then
    echo "$SCHEDULE $USER $CMD_OR_SCRIPT_PATH >> $SCRIPT_LOG_PATH 2>&1" > "$SNIPPET_PATH"
  else
    echo "$SCHEDULE $USER $CMD_OR_SCRIPT_PATH" > "$SNIPPET_PATH"
  fi

  printComment 'Checking snippet added to "/etc/cron.d"…'
  printSeparator
  ls -lha "$SNIPPET_PATH"
  printSeparator
  printComment 'Checking contents of snippet…'
  printSeparator
  cat "$SNIPPET_PATH"
  printSeparator
  printComment 'Script added to cron, using snippet.'
}

#-------------------------------------------------------------------------------
# # Checks to see if the "~/log" directory exist and creates it if not.
#-------------------------------------------------------------------------------
checkForAndCreateUserLogDir () {
  local LOG_DIR_TF="$(checkForFileOrDirectory "$USER_LOG_DIR_PATH")"

  printComment 'Checking for an "~/log" directory.'
  printComment "Check returned $LOG_DIR_TF."

  if [ "$USER_LOG_DIR_TF" = true ]; then
    printComment 'The "~/log" directory already exists.' 'warning'
  elif [ "$USER_LOG_DIR_TF" = false ]; then
    printComment 'Creating an "~/log" directory at:'
    printComment "$USER_LOG_DIR_PATH"
    createDirectory "$USER_LOG_DIR_PATH"

    setPermissions 700 "$USER_LOG_DIR_PATH"
    setOwner "$SUDO_USER" "$USER_LOG_DIR_PATH"
  fi
}

#-------------------------------------------------------------------------------
# Gets the script filename, then generates the snippet name, for the cronjob. 
# These are placed in global variables, "$CRON_SCRIPT_NAME",
# "$CRON_SNIPPET_NAME" and "$CRON_SCRIPT_PATH", for use in other functions.
#-------------------------------------------------------------------------------
getCronFilenames () {
  promptForUserInput 'What is the name of your script? This will also be the name of the snippet placed in "/etc/cron.d". You do not need to include the file extension ".sh"' 'It is assumed the script is placed in your home directory. If you wish to place it elsewhere do so, however you will need to update the generated snippet to point to this new location.'
  CRON_SCRIPT_NAME="$(getUserInput)"

  CRON_SNIPPET_NAME="$CRON_SCRIPT_NAME"
  CRON_SCRIPT_PATH="$USER_DIR_PATH/$CRON_SCRIPT_NAME.sh"
}

#-------------------------------------------------------------------------------
# Gets a schedule for the cronjob. This is placed in a global variable, 
# "$CRON_SCHEDULE", for use in other functions.
#-------------------------------------------------------------------------------
getCronSchedule () {
  promptForUserInput 'What schedule do you want this script to run on?' 'The format of the schedule should be five values separated by spaces, i.e. "x x x x x". You can use https://crontab.guru to help create the correct schedule.'
  CRON_SCHEDULE="$(getUserInput)"
}

