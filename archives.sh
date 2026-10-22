#!/bin/sh

# ------------------------------------------------------------------------------
# Functions for creating and extracting archives.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Creates a tar archive of a file or directory. Takes four arguments, two of
# which are mandatory:
#
# 1. "--date" – an optional flag, passed first, to add the date to the archive
#    file name;
# 2. "${1:?}" – the file or directory to archive, including directory path;
# 3. "${2:?}" – the archive file path, including file name and ".tar" extension;
#    and
# 4. "$3" – optional exclude patterns, separated by spaces, e.g.
#    "#recycle .DS_Store *.log".
#
# Paths in the archive start at the source's own name, e.g. archiving
# "/volumeX/docker" archives "docker/…" not "volumeX/docker/…".
#
# Exclude patterns cannot contain spaces, as spaces separate them. GNU tar
# matches patterns against any part of a path, e.g. "stack-one/cache" matches
# "docker/stack-one/cache".
#
# "--date" adds the current date to the end of the file name before any
# file extensions. "sed" matches the file name only and any suffix after ".tar"
# is kept. "printf" is used so backslashes in the path are not changed. The
# "sed" command uses the control character "\001" as its separator.
#
# Returns 1 with an error if an option is unknown or comes after the other
# arguments.
#
# Otherwise the function returns the exit status of "tar" for the caller to
# handle. For GNU tar:
#
# - 0 – success
# - 1 – some files changed while tar was reading them
# - 2 – fatal error
#
# tar prints its errors, and the names of files that changed, to stderr.
#
# N.B.
# Exclude patterns are split with parameter expansion rather than an unquoted
# "for" loop. Keeping them in quotes stops the shell replacing a wildcard with
# matching file names.
#
# A space is added to the end of "$3" for the loop to remove the last pattern
# like the others. Without it, the loop never ends. Empty patterns are skipped.
#
# "set --" clears the function's own arguments, then each pattern is added as a
# separate "--exclude=" argument. As the argument list keeps each item separate,
# "$@" can be passed to tar in quotes.
# ------------------------------------------------------------------------------
createTarArchive () {
  local DATE_TF=false
  local OPTION_COUNT=0
  local SOURCE_PATH
  local ARCHIVE_FILE_PATH
  local EXCLUDE_PATTERNS
  local EXCLUDE_PATTERN
  local SEPARATOR="$(printf '\001')"

  readOptions 'date=DATE_TF' "$@" || return 1
  shift "$OPTION_COUNT"

  SOURCE_PATH="${1:?}"
  ARCHIVE_FILE_PATH="${2:?}"
  EXCLUDE_PATTERNS="$3 "

  if [ "$DATE_TF" = true ]; then
    ARCHIVE_FILE_PATH="$(printf '%s\n' "$ARCHIVE_FILE_PATH" | sed "s${SEPARATOR}\([^/]*\)\.tar\([^/]*\)\$${SEPARATOR}\1-$(date +%Y-%m-%d).tar\2${SEPARATOR}")"
  fi

  set --

  while [ -n "$EXCLUDE_PATTERNS" ]; do
    EXCLUDE_PATTERN="${EXCLUDE_PATTERNS%% *}"
    EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS#* }"

    if [ -n "$EXCLUDE_PATTERN" ]; then
      set -- "$@" "--exclude=$EXCLUDE_PATTERN"
    fi
  done

  printComment "Archiving $SOURCE_PATH to $ARCHIVE_FILE_PATH…"

  tar -cf "$ARCHIVE_FILE_PATH" "$@" -C "$(dirname "$SOURCE_PATH")" "$(basename "$SOURCE_PATH")"
}
