#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for creating and extracting archives.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Creates a tar archive of a file or directory. Takes two mandatory arguments,
# followed by optional tar options:
#
# 1. "${1:?}" – the file or directory to archive, including directory path;
# 2. "${2:?}" – the archive file path, including file name and extension, i.e.
#    "/path/to/archive.tar"; and
# 3. "$@" – any remaining arguments.
#
# Paths in the archive start at the source's own name, so archiving
# "/volumeX/docker" archives "docker/…" not "volumeX/docker/…".
#
# Arguments are passed to tar unchanged. Any shell expansion of wildcards
# happens in the caller's code, i.e. --exclude '*.log' reaches tar as typed,
# rather than being replaced with matching file names such as "a.log".
#
# The function returns tar's exit status. For GNU tar, 0 is success, 1 means
# some files changed while tar was reading them, and 2 is a fatal error.
#
# N.B.
# tar prints its own errors, and the names of files that changed while it read
# them, to stderr. As per:
#
# - https://www.gnu.org/software/tar/manual/html_node/Synopsis.html
# - https://www.gnu.org/software/tar/manual/html_node/Synopsis.html#exit-status
#-------------------------------------------------------------------------------
createTarArchive () {
  local SOURCE_PATH="${1:?}"
  local ARCHIVE_FILE_PATH="${2:?}"
  shift 2

  printComment "Archiving $SOURCE_PATH to $ARCHIVE_FILE_PATH…"

  tar -cf "$ARCHIVE_FILE_PATH" "$@" -C "$(dirname "$SOURCE_PATH")" "$(basename "$SOURCE_PATH")"
}
