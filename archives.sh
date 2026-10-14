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
# 3. "$@" – any remaining arguments, passed to tar unchanged as extra options,
#    i.e. "--exclude=pattern".
#
# Paths in the archive start at the source's own name, so archiving
# "/volumeX/docker" stores "docker/…" rather than "volumeX/docker/…".
#
# The function returns tar's exit status. For GNU tar, 0 is success, 1 means
# some files changed while tar was reading them, and 2 is a fatal error.
#
# N.B.
# The archive's parent directory must already exist.
#
# If the caller builds tar options with an unquoted command substitution, i.e.
# "$(getTarExcludeFlags)", wildcard matching must be turned off with "set -f"
# first, or the shell may expand the patterns before tar sees them.
#
# tar prints its own errors, and the names of files that changed while it read
# them, to stderr.
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
