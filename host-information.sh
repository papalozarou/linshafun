#!/bin/sh

# ------------------------------------------------------------------------------
# Functions for getting OS information.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Checks if the host machine is a Raspberry Pi. Returns 0 if it is, non-zero if
# it is not. Takes no arguments.
# 
# N.B.
# The check is done by looking for "Raspberry Pi" in "/proc/device-tree/model",
# using "grep -qi" to make the search quiet (q) and case insensitive (i).
#
# If the file doesn't exist (e.g. not a Raspberry Pi), any error output is
# redirected to "/dev/null" and the function returns 2.
# ------------------------------------------------------------------------------
checkIfRaspberryPi () {
  grep -qi 'raspberry pi' /proc/device-tree/model 2>/dev/null
}

# ------------------------------------------------------------------------------
# Checks if the script is being run as a given user. Takes one argument:
#
# 1. "${1:-root}" – the user name, defaulting to "root".
#
# Returns 0 if it is, 1 if it is not.
# ------------------------------------------------------------------------------
checkIfRunAsUser () {
  local USER_NAME="${1:-root}"

  [ "$(id -un)" = "$USER_NAME" ]
}

# ------------------------------------------------------------------------------
# Checks if the script is being run with "sudo". Returns 0 if it is, 1 if it is
# not. Takes no arguments.
#
# N.B.
# Both checks are needed. A script run as root without "sudo", e.g. from a root
# login, has no "$SUDO_USER", which setup scripts need for ownership and paths.
# "$SUDO_USER" is an ordinary variable that anyone can set, so it alone does not
# prove the script is running as root.
# ------------------------------------------------------------------------------
checkIfRunWithSudo () {
  [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]
}

# ------------------------------------------------------------------------------
# Checks if the system was rebooted by parsing the output of "who -b" into 
# seconds, and comparing against the current time. Takes one argument:
# 
# 1. "${1:-60}" – the time in seconds within which a reboot is considered 
#    recent, defaulting to 60 seconds.
#
# Returns 0 if the system was rebooted within the given timeframe, 1 if not, and
# 2 if the timeframe is not a number.
# ------------------------------------------------------------------------------
checkIfSystemRebooted () {
  local REBOOT_TIMEFRAME="${1:-60}"
  local CURRENT_TIME="$(date +%s)"
  local LAST_BOOT="$(date -d "$(who -b | awk '{print $3" "$4}')" +%s 2>/dev/null)"
  local TIME_DIFF=$((CURRENT_TIME - LAST_BOOT))

  [ "$TIME_DIFF" -le "$REBOOT_TIMEFRAME" ]
}

# ------------------------------------------------------------------------------
# Compares the current Linux distribution version against a given version. Takes 
# one mandatory argument:
#
# 1. "${1:?}" – the OS version number to compare to.
#
# The function returns 0 if the current OS is less than or equal to the given 
# version, and 1 if it is higher.
#
# N.B.
# As shell can't compare floating decimal points, both the comparison OS and the
# current OS are stripped to their major version number. As per:
#
# - https://unix.stackexchange.com/a/569768
#
# The test is negated with "!" rather than written as "-le", so a version that
# is not a number still returns 0, as "-gt" fails with status 2 and "!" turns
# any failure into 0.
# ------------------------------------------------------------------------------
compareOsVersion () {
  local COMPARISON_OS="$(echo "${1:?}" | cut -d'.' -f1)"
  local CURRENT_OS="$(getOsVersion | cut -d'.' -f1)"

  ! [ "$CURRENT_OS" -gt "$COMPARISON_OS" ]
}

# ------------------------------------------------------------------------------
# Gets the host machine architecture, e.g. amd64 or arm64. Takes no arguments.
# ------------------------------------------------------------------------------
getHostArchitecture () {
  local HOST_ARCHITECTURE="$(dpkg --print-architecture)"

  echo "$HOST_ARCHITECTURE"
}

# ------------------------------------------------------------------------------
# Gets the Linux kernel version number the host machine is running. Takes no
# arguments.
# ------------------------------------------------------------------------------
getKernelVersion () {
  local KERNEL_VERSION="$(uname -r)"

  echo "$KERNEL_VERSION"
}

# ------------------------------------------------------------------------------
# Gets the Linux distribution codename the host machine is running, e.g. 
# bookworm, focal or jammy. Takes no arguments.
# ------------------------------------------------------------------------------
getOsCodename () {
  local OS_CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"

  echo "$OS_CODENAME"
}

# ------------------------------------------------------------------------------
# Gets the Linux distribution the host machine is running, e.g. ubuntu or
# debian. Takes no arguments.
# ------------------------------------------------------------------------------
getOsDistribution () {
  local OS_DISTRIBUTION="$(. /etc/os-release && echo "$ID")"

  echo "$OS_DISTRIBUTION"
}

# ------------------------------------------------------------------------------
# Gets the Linux distribution version number the host machine is running. Takes
# no arguments.
# ------------------------------------------------------------------------------
getOsVersion () {
  # local OS_VERSION="$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')"
  local OS_VERSION="$(. /etc/os-release && echo "$VERSION_ID")"

  echo "$OS_VERSION"
}

# ------------------------------------------------------------------------------
# Gets the Raspberry Pi model number if the host machine is a Raspberry Pi. If 
# the host machine is not a Raspberry Pi an empty string is returned. Takes no
# arguments.
# 
# N.B.
# The model number is extracted from the binary file "/proc/device-tree/model", 
# trimming null bytes with "tr -d '\0'" to enable safe parsing as text, then 
# using "grep -oi" to case insensitively match only the pattern 
# "raspberry pi [0-9]", and then cut to extract just the model number.
# ------------------------------------------------------------------------------
getRaspberryPiModel () {
  local MODEL_FILE_PATH='/proc/device-tree/model'
  local MODEL

  if checkIfRaspberryPi; then
    MODEL="$(tr -d '\0' < "$MODEL_FILE_PATH" | grep -oi 'raspberry pi [0-9]' | cut -d' ' -f3)"

    echo "$MODEL"
  fi
}