#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for adding to a user, or root, crontab.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds a script, on a schedule, to a given user's crontab, via a snipper in 
# "/etc/cron.d". Takes four mandatory arguments:
#
# 1. "${1:?}" – a username, defaulting to "root";
# 2. "${2:?}" – the filename of the script, including directory path, defaulting 
#    to the global variable "$CRON_SCRIPT";
# 3. "${3:?}" – the cron schedule, in "* * * * *" format, defaulting to the 
#    global variable "$CRON_SCHEDULE"; and
# 4. "${4:?}" – the snippet name to be placed in "/etc/cron.d", defaulting to 
#    the global variable "$CRON_SNIPPET".
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
  local SCRIPT="${2:-"$CRON_SCRIPT"}"
  local SCHEDULE="${3:-"$CRON_SCHEDULE"}"
  local SNIPPET="/etc/cron.d/${4:-"$CRON_SNIPPET"}"

  printComment 'Adding the following to the system crontab, as a snippet in "/etc/cron.d":'
  printComment "$SCHEDULE $USER $SCRIPT"

  echo "$SCHEDULE $USER $SCRIPT" > "$SNIPPET"

  printSeparator
  ls -lha "$SNIPPET"
  printSeparator
  cat "$SNIPPET"
  printSeparator
  printComment 'Script added.'
}

#-------------------------------------------------------------------------------
# Gets the script filename, then generates the snippet name, for the cronjob. 
# These are placed in global variables, "$CRON_SCRIPT" and "$CRON_SNIPPET", for 
# use in other functions.
#-------------------------------------------------------------------------------
getCronFilenames () {
  promptForUserInput 'What is the name of your script? You do not need to include the file extension ".sh"' 'It is assumed the script is placed in your home directory. If you wish to place it elsewhere do so, however you will need to update the generated snippet to point to this new location.'
  CRON_SCRIPT="$(getUserInput)"

  CRON_SNIPPET="$CRON_SCRIPT"
  CRON_SCRIPT="$USER_DIR/$CRON_SCRIPT.sh"
}

#-------------------------------------------------------------------------------
# Gets a schedule for the cronjob. This is placed in a global variable, 
# "$CRON_SCHEDULE", for use in other functions.
#-------------------------------------------------------------------------------
getCronSchedule () {
  promptForUserInput 'What schedule do you want this script to run on?' 'The format of the schedule should be five values separated by spaces, i.e. "x x x x x". You can use https://crontab.guru to help create the correct schedule.'
  CRON_SCHEDULE="$(getUserInput)"
}

