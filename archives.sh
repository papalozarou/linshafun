#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for creating and extracting archives.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Creates a tar archive of a file or directory. Takes four arguments, two of
# which are mandatory:
#
# 1. "${1:?}" – the file or directory to archive, including directory path;
# 2. "${2:?}" – the archive file path, including file name and ".tar" extension;
# 3. "$3" – optional exclude patterns, separated by spaces, e.g.
#    "#recycle .DS_Store *.log"; and
# 4. "${4:-false}" – an optional flag to add the date to the archive file name,
#    defaulting to "false".
#
# Paths in the archive start at the source's own name, e.g. archiving
# "/volumeX/docker" archives "docker/…" not "volumeX/docker/…".
#
# Exclude patterns cannot contain spaces, as spaces separate them. GNU tar
# matches patterns against any part of a path, e.g. "stack-one/cache" matches
# "docker/stack-one/cache".
#
# When the date flag is "true", the date is added to the end of the file name
# before any file extensions. An archive created earlier on the same day is
# overwritten.
#
# The function returns the exit status of "tar" for the caller to handle. For
# GNU tar:
#
# - 0 – success
# - 1 – some files changed while tar was reading them
# - 2 – fatal error
#
# tar prints its errors, and the names of files that changed, to stderr.
#
# N.B.
# "sed" matches the file name only. Any suffix after ".tar" is kept. "printf"
# is used so backslashes in the path are not changed.
#
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
#-------------------------------------------------------------------------------
createTarArchive () {
  local SOURCE_PATH="${1:?}"
  local ARCHIVE_FILE_PATH="${2:?}"
  local EXCLUDE_PATTERNS="$3 "
  local DATE_TF="${4:-false}"
  local EXCLUDE_PATTERN

  if [ "$DATE_TF" = true ]; then
    ARCHIVE_FILE_PATH="$(printf '%s\n' "$ARCHIVE_FILE_PATH" | sed "s|\([^/]*\)\.tar\([^/]*\)$|\1-$(date +%Y-%m-%d).tar\2|")"
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
