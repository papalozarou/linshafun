#!/bin/sh

# ------------------------------------------------------------------------------
# Functions to print comments, help with comment consistency, and write and
# rotate comment logs.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Comment variables.
#
# N.B.
# "COMMENT_COLOUR_PREFIX" and "COMMENT_COLOUR_WARN" use the ANSI escape code for
# green and yellow respectively. The "COMMENT_COLOUR_RESET" variable resets the 
# ANSI colour.
# 
# Yes, yes we are using the latin phrase, not the abbreviation, for 
# "COMMENT_PREFIX_WARN".
# ------------------------------------------------------------------------------
COMMENT_COLOUR_PREFIX='\033[32m'
COMMENT_COLOUR_WARN='\033[33m'
COMMENT_COLOUR_ERROR='\033[31m'
COMMENT_COLOUR_RESET='\033[0m'
COMMENT_PREFIX='SETUP SCRIPT: '
COMMENT_PREFIX_WARN='   NOTA BENE: '
COMMENT_PREFIX_ERROR=' ***ERROR***: '
COMMENT_SEPARATOR='------------------------------------------------------------------'
COMMENT_LOG_PATH=
COMMENT_LOG_TIMESTAMP_FORMAT='%Y-%m-%d %H:%M:%S'

# ------------------------------------------------------------------------------
# Initialises comment logging to a file for the current script run. Takes four
# arguments, two of which are mandatory:
#
# 1. "${1:?}" – the log file, including directory path;
# 2. "${2:?}" – the log user;
# 3. "${3:-$2}" – the log group, defaulting to the log user; and
# 4. "${4:-7}" – the maximum age, in days, to keep archived logs for,
#    defaulting to 7.
#
# The function:
#
# 1. creates the parent of the log directory if it does not exist;
# 2. creates the log directory if it does not exist;
# 3. sets the log path;
# 4. rotates the current log;
# 5. creates the log file; and
# 6. sets the permissions and ownership for the log directory and its files.
#
# The parent of the log directory is created first, with "700" and the log
# user as owner, as "createDirectory" doesn't create missing parent
# directories, and a directory created as root can't be opened by the user.
# The owner is set last, so the new log and every archived log belong to the
# user. "700" on directories and "600" on files keep the logs private, as they
# list file names and paths.
#
# N.B.
# "COMMENT_LOG_PATH" is set after creating the log directory, as "printLogLine"
# writes to it, and "createDirectory" prints output before the directory exists.
#
# Setting it before rotating means output from removing archived logs is written
# to the new log, as the current log is renamed first. Nothing must be printed
# between setting it and renaming the current log, or it is written to the
# current log instead.
#
# If the log file can't be created, "COMMENT_LOG_PATH" is cleared before the
# error is printed, so the script carries on printing to the terminal only.
# Without this, every later comment would also print an error, as it fails to
# write to the missing log. The function then returns 1, without setting the
# owner or permissions of the log directory.
# ------------------------------------------------------------------------------
initialiseCommentLogs () {
  local LOG_FILE_PATH="${1:?}"
  local LOG_USER="${2:?}"
  local LOG_GROUP="${3:-$LOG_USER}"
  local LOG_MAX_AGE_DAYS="${4:-7}"
  local LOG_DIR_PATH="${LOG_FILE_PATH%/*}"

  createDirectory "$(dirname "$LOG_DIR_PATH")" '700' "$LOG_USER" "$LOG_GROUP"
  createDirectory "$LOG_DIR_PATH"

  COMMENT_LOG_PATH="$LOG_FILE_PATH"

  rotateCommentLog "$LOG_FILE_PATH" "$LOG_MAX_AGE_DAYS"

  if ! touch "$COMMENT_LOG_PATH"; then
    COMMENT_LOG_PATH=
    printComment --error "Failed to create the log file at $LOG_FILE_PATH. Logging is off for this run."

    return 1
  fi

  setOwner "$LOG_USER" "$LOG_DIR_PATH" "$LOG_GROUP"
  setPermissions --recursive '700' "$LOG_DIR_PATH" '600'
}

# ------------------------------------------------------------------------------
# Prints a comment of any length, via "printLine". Takes three arguments, one of
# which is mandatory:
# 
# 1. "--warning" – an optional flag, passed first, to print the comment as a
#    warning;
# 2. "--error" – an optional flag, passed first, to print the comment as an
#    error; and
# 3. "${1:?}" – the full comment to print.
# 
# The comment is split into words and printed in lines that do not exceed the
# standard terminal length of 80 characters, including prefix.
#
# Returns 1 with an error if an option is unknown or comes after the comment,
# if both "--warning" and "--error" are passed, or if more than one comment is
# passed.
# 
# The function handles line breaks and ensures that the last line is printed 
# even if it does not reach the maximum length, via the last for loop.
# 
# N.B.
# "$COMMENT" is not quoted in the "for" loop so it is split into words. "set -f"
# stops the shell also replacing wildcards with matching file names, and is
# turned off again after the loop.
#
# A comment that starts with "-" must follow "--", e.g.
# "printComment -- "$COMMENT_SEPARATOR"", or it is read as an unknown option.
# Pass "--" before any comment that starts with a variable, as its value could
# start with "-".
# ------------------------------------------------------------------------------
printComment () {
  local WARNING_TF=false
  local ERROR_TF=false
  local OPTION_COUNT=0
  local COMMENT_TYPE=
  local COMMENT
  local LINE_LENGTH=66
  local CURRENT_LINE=
  local WORD

  readOptions 'warning=WARNING_TF error=ERROR_TF' "$@" || return 1
  shift "$OPTION_COUNT"

  if [ "$#" -gt 1 ]; then
    printComment --error "printComment takes one comment, but was given $#."

    return 1
  fi

  if [ "$WARNING_TF" = true ] && [ "$ERROR_TF" = true ]; then
    printComment --error 'printComment takes "--warning" or "--error", not both.'

    return 1
  fi

  COMMENT="${1:?}"

  if [ "$WARNING_TF" = true ]; then
    COMMENT_TYPE='warning'
  elif [ "$ERROR_TF" = true ]; then
    COMMENT_TYPE='error'
  fi

  set -f

  for WORD in $COMMENT; do
    if [ -z "$CURRENT_LINE" ]; then
      CURRENT_LINE="$WORD"
    elif [ $((${#CURRENT_LINE} + ${#WORD} + 1)) -le "$LINE_LENGTH" ]; then
      CURRENT_LINE="$CURRENT_LINE $WORD"
    else
      printLine "$CURRENT_LINE" "$COMMENT_TYPE"
      CURRENT_LINE="$WORD"
    fi
  done

  set +f

  printLine "$CURRENT_LINE" "$COMMENT_TYPE"
}

# ------------------------------------------------------------------------------
# Prints a comment line with the specified prefix and colour. Takes two
# arguments, one of which is mandatory:
# 
# 1. "${1:?}" – the comment line to print; and
# 2. "${2:-regular}" – a flag indicating if the comment is "regular", a 
#    "warning", or an "error", defaulting to "regular".
#
# The comment line is printed in the specified colour, with the appropriate 
# prefix.
# 
# N.B.
# In the "printf" commands:
# 
# - "%b" interprets escape sequences in the corresponding argument, allowing the
#   use of ANSI escape codes for colour formatting;
# - "%s" prints a string; and
# - "\n" is used to ensure that each line ends properly, especially when the 
#   last line does not reach the maximum length.
#
# Warnings and errors go to stderr, so they are not captured when called using
# "$(…)".
# ------------------------------------------------------------------------------
printLine () {
  local LINE="${1:?}"
  local TYPE="${2:-regular}"

  if [ "$TYPE" = 'warning' ]; then
    printf "%b%s%s\n%b" "$COMMENT_COLOUR_WARN" "$COMMENT_PREFIX_WARN" "$LINE" "$COMMENT_COLOUR_RESET" >&2
  elif [ "$TYPE" = 'error' ]; then
    printf "%b%s%s\n%b" "$COMMENT_COLOUR_ERROR" "$COMMENT_PREFIX_ERROR" "$LINE" "$COMMENT_COLOUR_RESET" >&2
  else
    printf "%b%s%b%s\n" "$COMMENT_COLOUR_PREFIX" "$COMMENT_PREFIX" "$COMMENT_COLOUR_RESET" "$LINE"
  fi

  printLogLine "$LINE" "$TYPE"
}

# ------------------------------------------------------------------------------
# Logs a comment line using the same prefixes as terminal output. Takes two
# arguments, one of which is mandatory:
#
# 1. "${1:?}" – the comment line to log; and
# 2. "${2:-regular}" – a flag indicating if the comment is "regular", a
#    "warning", or an "error", defaulting to "regular".
#
# Each line is prefixed with the date and time in the format set by
# "COMMENT_LOG_TIMESTAMP_FORMAT", e.g.:
#
# 2026-10-10 05:00:03 SETUP SCRIPT: Stopping stacks.
#
# Nothing is logged until "initialiseCommentLogs" has been called.
# ------------------------------------------------------------------------------
printLogLine () {
  local LINE="${1:?}"
  local TYPE="${2:-regular}"
  local TIMESTAMP=

  if [ -z "$COMMENT_LOG_PATH" ]; then
    return 0
  fi

  TIMESTAMP="$(date "+$COMMENT_LOG_TIMESTAMP_FORMAT")"

  if [ "$TYPE" = 'warning' ]; then
    printf "%s %s%s\n" "$TIMESTAMP" "$COMMENT_PREFIX_WARN" "$LINE" >> "$COMMENT_LOG_PATH"
  elif [ "$TYPE" = 'error' ]; then
    printf "%s %s%s\n" "$TIMESTAMP" "$COMMENT_PREFIX_ERROR" "$LINE" >> "$COMMENT_LOG_PATH"
  else
    printf "%s %s%s\n" "$TIMESTAMP" "$COMMENT_PREFIX" "$LINE" >> "$COMMENT_LOG_PATH"
  fi
}

# ------------------------------------------------------------------------------
# Tells the user that the script is exiting. Takes one argument:
#
# 1. "--changes" – an optional flag to print the "changes were made" warning,
#    instead of "Exiting script with no changes.".
# 
# Returns 1 with an error if an option is unknown, or if any other argument is
# passed.
# ------------------------------------------------------------------------------
printScriptExiting () {
  local CHANGES_TF=false
  local OPTION_COUNT=0

  readOptions 'changes=CHANGES_TF' "$@" || return 1
  shift "$OPTION_COUNT"

  if [ "$#" -gt 0 ]; then
    printComment --error 'printScriptExiting takes no arguments other than "--changes".'

    return 1
  fi

  printSeparator

  if [ "$CHANGES_TF" = true ]; then
    printComment --warning 'Exiting script, however some changes were made – please review the script output.'
  else
    printComment 'Exiting script with no changes.'
  fi

  printSeparator
}

# ------------------------------------------------------------------------------
# Tells the user that the script has finished. Takes no arguments.
# ------------------------------------------------------------------------------
printScriptFinished () {
  printSeparator
  printComment 'Script finished.'
  printSeparator
}

# ------------------------------------------------------------------------------
# Prints comment separator. Takes no arguments.
# ------------------------------------------------------------------------------
printSeparator () {
  printComment -- "$COMMENT_SEPARATOR"
}

# ------------------------------------------------------------------------------
# Tells the user an action is taking place and a wait is needed. Takes three
# arguments, two of which are mandatory:
# 
# 1. "${1:?}" – the service the action is being performed on;
# 2. "${2:?}" – the action being performed; and
# 3. "${3:-"60"}" – the length of time, in seconds to wait, defaults to 60.
# ------------------------------------------------------------------------------
printServiceWait () {
  local SERVICE="${1:?}"
  local ACTION="${2:?}"
  local WAIT="${3:-"60"}"

  printComment "To give $SERVICE time to $ACTION we will wait at least $WAIT seconds."
  printComment --warning 'Please do not stop the script.'
  
  sleep "$WAIT"
}

# ------------------------------------------------------------------------------
# Reads the options at the start of a function's arguments, and sets a variable
# to "true" for each option found. Takes two or more arguments, one of which is
# mandatory:
#
# 1. "${1:?}" – the options the function accepts, separated by spaces, each as
#    "<option name>=<variable name>", e.g. "warning=WARNING_TF error=ERROR_TF";
#    and
# 2. "$@" – the function's own arguments, passed as "$@".
#
# Options are read from the front of the arguments, and reading stops at the
# first argument that doesn't start with "-", or at "--". "OPTION_COUNT" is set
# to the number of arguments read, including "--", so the calling function can
# remove them with "shift "$OPTION_COUNT"".
#
# The function prints an error and returns 1 if:
#
# 1. an argument starting with "-" isn't one of the accepted options, e.g.
#    "--warnig", "-w" or "----------"; or
# 2. one of the accepted options appears after the first argument that isn't an
#    option, e.g. "printComment 'Text.' --warning".
#
# The second check is skipped after "--", so a value that matches an option
# name can be passed after it.
#
# N.B.
# The calling function must declare "OPTION_COUNT" and each option's variable
# as local, with a default, before calling this function, e.g.
# "local DATE_TF=false". Variables set by a function belong to the nearest
# calling function that declared them local, so they don't leak into the
# script.
#
# "eval" only sets variable names written in the calling function's own code,
# never a value passed by a caller.
#
# Long options are used, e.g. "--warning", so options can't be grouped as in
# "rm -rf". "getopts" only reads single character options.
# ------------------------------------------------------------------------------
readOptions () {
  local OPTION_SPECS=" ${1:?} "
  local OPTION_NAME
  local VAR_NAME

  shift
  OPTION_COUNT=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --) OPTION_COUNT=$((OPTION_COUNT + 1)); return 0 ;;
      --*) OPTION_NAME="${1#--}" ;;
      -*) printComment --error "Unknown option $1."; return 1 ;;
      *) break ;;
    esac

    case "$OPTION_SPECS" in
      *" $OPTION_NAME="*) ;;
      *) printComment --error "Unknown option $1."; return 1 ;;
    esac

    VAR_NAME="${OPTION_SPECS#*" $OPTION_NAME="}"
    VAR_NAME="${VAR_NAME%% *}"
    eval "$VAR_NAME=true"
    OPTION_COUNT=$((OPTION_COUNT + 1))
    shift
  done

  for OPTION_NAME in "$@"; do
    case "$OPTION_NAME" in
      --*) ;;
      *) continue ;;
    esac

    case "$OPTION_SPECS" in
      *" ${OPTION_NAME#--}="*) printComment --error "Option $OPTION_NAME must come before the other arguments."; return 1 ;;
    esac
  done
}

# ------------------------------------------------------------------------------
# Removes archived comment logs older than a given number of days. Takes two
# mandatory arguments:
#
# 1. "${1:?}" – the log file, including directory path; and
# 2. "${2:?}" – the maximum age, in days, to keep archived logs for.
#
# Archived logs are files named "<log file name>.*" in the log directory, as
# created by "rotateCommentLog". The current log file is never removed.
#
# N.B.
# "-mtime" ignores part days, so a maximum age of "7" removes archived logs at
# least 8 full days old.
#
# "find" also searches subdirectories of the log directory, as "-maxdepth" is
# not POSIX.
#
# "$ARCHIVED_LOG_FILE_PATHS" is not quoted when passed to
# "removeFilesOrDirectories", to allow for word splitting, so the log directory
# path must not contain spaces. A path with spaces is split into separate paths,
# and any of those that exist are removed, e.g. "/volume1/my logs" removes the
# "/volume1/my" directory if it exists.
# ------------------------------------------------------------------------------
removeArchivedCommentLogs () {
  local LOG_FILE_PATH="${1:?}"
  local LOG_MAX_AGE_DAYS="${2:?}"
  local LOG_DIR_PATH="${LOG_FILE_PATH%/*}"
  local LOG_FILE_NAME="${LOG_FILE_PATH##*/}"
  local ARCHIVED_LOG_FILE_PATHS="$(find "$LOG_DIR_PATH" -type f -name "$LOG_FILE_NAME.*" -mtime "+$LOG_MAX_AGE_DAYS")"

  if [ -z "$ARCHIVED_LOG_FILE_PATHS" ]; then
    return 0
  fi

  removeFilesOrDirectories $ARCHIVED_LOG_FILE_PATHS
}

# ------------------------------------------------------------------------------
# Removes the ANSI colour codes from comment output if it is not going to a
# terminal. Takes no arguments.
#
# Call it at the start of a script that runs on a schedule, e.g. from DSM
# Task Scheduler or cron. Their output is saved to a file or sent by email,
# where the colour codes would show as raw characters, e.g. "^[[32m". When the
# same script is run by hand, its output keeps its colours.
#
# N.B.
# The log file written by "printLogLine" never contains colour codes, so this
# function only affects the script's own output.
# ------------------------------------------------------------------------------
removeCommentColoursIfNotTerminal () {
  if [ ! -t 1 ]; then
    COMMENT_COLOUR_PREFIX=''
    COMMENT_COLOUR_WARN=''
    COMMENT_COLOUR_ERROR=''
    COMMENT_COLOUR_RESET=''
  fi
}

# ------------------------------------------------------------------------------
# Rotates a comment log so each script run starts with a fresh log. Takes two
# mandatory arguments:
#
# 1. "${1:?}" – the log file, including directory path; and
# 2. "${2:?}" – the maximum age, in days, to keep archived logs for.
#
# The function:
#
# 1. renames the current log file to "<log file name>.<date and time>", if it
#    exists and is not empty, e.g. "docker-backup.log.2026-10-10-05-00-03"; and
# 2. removes archived logs older than the maximum age, via
#    "removeArchivedCommentLogs".
#
# The date and time are read from the timestamp at the start of the log's first
# line, so the archive is named after when the log was started. If the first
# line does not start with a timestamp, the current date and time are used with
# an "-untimestamped" suffix, e.g.
# "docker-backup.log.2026-10-10-05-00-03-untimestamped".
#
# The suffix stops the archive having the same name as the next archive, as the
# new log is started in the same second, which would overwrite it.
#
# N.B.
# The timestamp length is taken from the current date and time, so
# "COMMENT_LOG_TIMESTAMP_FORMAT" must produce a fixed length string.
#
# Spaces and colons in the timestamp are replaced with hyphens to keep the
# archived log file name free of them.
#
# Renaming keeps the file's modification time, so an archived log's age is
# measured from the last line written to it, not from when it was archived.
# ------------------------------------------------------------------------------
rotateCommentLog () {
  local LOG_FILE_PATH="${1:?}"
  local LOG_MAX_AGE_DAYS="${2:?}"
  local CURRENT_TIMESTAMP="$(date "+$COMMENT_LOG_TIMESTAMP_FORMAT")"
  local LOG_TIMESTAMP=

  if [ -f "$LOG_FILE_PATH" ] && [ -s "$LOG_FILE_PATH" ]; then
    LOG_TIMESTAMP="$(getFirstCharsFromFirstLine "$LOG_FILE_PATH" "${#CURRENT_TIMESTAMP}")"

    case "$LOG_TIMESTAMP" in
      ''|*[!0-9\ :-]*) LOG_TIMESTAMP="$CURRENT_TIMESTAMP-untimestamped" ;;
    esac

    renameFileOrDirectory "$LOG_FILE_PATH" "$LOG_FILE_PATH.$(printf '%s\n' "$LOG_TIMESTAMP" | tr ' :' '--')"
  fi

  removeArchivedCommentLogs "$LOG_FILE_PATH" "$LOG_MAX_AGE_DAYS"
}
