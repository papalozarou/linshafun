#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for creating and extracting archives.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Creates a tar archive of a file or directory. Takes three arguments:
#
# 1. "${1:?}" – the file or directory to archive, including directory path;
# 2. "${2:?}" – the archive file path, including file name and extension, i.e.
#    "/path/to/archive.tar"; and
# 3. "$3" – optional exclude patterns as one quoted string, separated by
#    spaces, i.e. "#recycle .DS_Store *.log".
#
# Paths in the archive start at the source's own name, so archiving
# "/volumeX/docker" archives "docker/…" not "volumeX/docker/…".
#
# N.B.
# Returns tar's exit status. For GNU tar, 0 is success, 1 means some files
# changed while tar was reading them, and 2 is a fatal error. tar prints its
# errors, and the names of files that changed, to stderr.
#
# Patterns are kept in quotes throughout, so the shell never replaces a
# wildcard such as "*.log" with matching file names. This is why the patterns
# are split with parameter expansion rather than an unquoted "for" loop.
# Patterns cannot contain spaces, as spaces separate them.
#
# A space is added to the end of "$3" so the last pattern is removed from the
# string like the others, otherwise the loop never ends. Empty patterns, from
# double spaces or an empty "$3", are skipped, as bsdtar fails on "--exclude=".
#
# "set --" first clears the function's own arguments, then each pattern is
# added as a separate "--exclude=" argument. Unlike a variable, the argument
# list keeps each item separate, so "$@" can be passed to tar in quotes.
#
# GNU tar matches an exclude pattern against any part of a path, so
# "stack-one/cache" matches "docker/stack-one/cache". As per:
#
# - https://www.gnu.org/software/tar/manual/html_node/Synopsis.html
# - https://www.gnu.org/software/tar/manual/html_node/Synopsis.html#exit-status
# - https://www.gnu.org/software/tar/manual/html_node/controlling-pattern_002dmatching.html
#-------------------------------------------------------------------------------
createTarArchive () {
  local SOURCE_PATH="${1:?}"
  local ARCHIVE_FILE_PATH="${2:?}"
  local EXCLUDE_PATTERNS="$3 "
  local EXCLUDE_PATTERN

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
