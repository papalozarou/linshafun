#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for adding to a user, or root, crontab.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds a script, on a schedule, to a given user's crontab, via a snipper in 
# "/etc/cron.d". Takes four mandatory arguments:
#
# 1. "${1:?}" – the filename of the script, including directory path;
# 2. "${2:?}" – the cron schedule, in "* * * * *" format, defaulting to the 
#    global variable "$CRON_SCHEDULE".
# 3. "${3:?}" – the snippet name to be placed in "/etc/cron.d"; and
# 4. "${4:?}" – a username, defaulting to "root".
# 
# N.B.
# If using the global variable "$CRON_SCHEDULE" this must be assigned first 
# using "getCronSchedule".
#-------------------------------------------------------------------------------
addScriptToCron () {
  local SCRIPT="${1:?}"
  local SCHEDULE="${2:-"$CRON_SCHEDULE"}"
  local CROND_SNIPPET="/etc/cron.d/${3:?}"
  local CRON_USER="${4:-"root"}"

  printComment 'Adding the following to the system crontab, as a snippet in "/etc/cron.d":'
  printComment "$SCHEDULE $CRON_USER $SCRIPT"

  echo "$SCHEDULE $CRON_USER $SCRIPT" > "$CROND_SNIPPET"

  printSeparator
  ls -lha "$CROND_SNIPPET"
  printSeparator
  cat "$CROND_SNIPPET"
  printSeparator
  printComment 'Script added.'
}

#-------------------------------------------------------------------------------
# Gets a schedule for the cronjob. This is placed in a global variable, 
# "$CRON_SCHEDULE", for use with other functions.
#-------------------------------------------------------------------------------
getCronSchedule () {
  promptForUserInput 'What schedule do you want this script to run on?' 'The format of the schedule should be five values separated by spaces, i.e. "x x x x x". You can use https://crontab.guru to help create the correct schedule.'
  CRON_SCHEDULE="$(getUserInput)"
}

