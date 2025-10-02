#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for initialising a host, mainly Raspberry Pi models.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds cgroup memory options to the cmdline.txt file to enable memory limits for 
# containers in Docker Compose.
# 
# The function checks for the cmdline.txt file first in "/boot/firmware", then 
# in "/boot", adjusting "$CMDLINE_PATH" accordingly.
#
# If the cmdline.txt file does not exist in either location, the function exits
# with an error.
#-------------------------------------------------------------------------------
addPiCgroupOptionsToCmdline () {
  local CMDLINE_PATH="$(checkPiCmdlineLocation)"
  local CGROUP_OPTIONS="cgroup_memory=1 cgroup_enable=memory"

  if [ -z "$CMDLINE_PATH" ]; then
    printComment 'A cmdline.txt file was not found in /boot/firmware or /boot.' 'error'

    return 1
  else
    printComment 'Adding cgroup memory options to cmdline.txt file at:' 
    printComment "$CMDLINE_PATH"
    
    sudo sh -c "sed 's/\(.*\)rootwait/\1$CGROUP_OPTIONS rootwait/' \"$CMDLINE_PATH\" > \"$CMDLINE_PATH.tmp\" && mv \"$CMDLINE_PATH.tmp\" \"$CMDLINE_PATH\""

    printSeparator
    grep 'cgroup_memory' "$CMDLINE_PATH"
    printSeparator
    printComment 'Cgroup memory options added. A reboot is required for changes to take effect.' 'warning'
  fi
}

#-------------------------------------------------------------------------------
# Prepends video mode settings to the cmdline.txt file to enable dual 1080p 
# monitors.
# 
# The function checks for the cmdline.txt file first in "/boot/firmware", then 
# in "/boot", adjusting "$CMDLINE_PATH" accordingly.
#
# If the cmdline.txt file does not exist in either location, the function exits
# with an error.
#-------------------------------------------------------------------------------
addPiVideoModesToCmdline () {
  local CMDLINE_PATH="$(checkPiCmdlineLocation)"
  local VIDEO_MODES="video=HDMI-A-1:1920x1080M@60 video=HDMI-A-2:1920x1080M@60"

  if [ -z "$CMDLINE_PATH" ]; then
    printComment 'cmdline.txt file not found in /boot/firmware or /boot.' 'error'

    return 1
  else
    printComment 'Adding video modes to cmdline.txt file at:' 
    printComment "$CMDLINE_PATH"

    sudo sh -c "echo \"$VIDEO_MODES \$(head -n1 $CMDLINE_PATH)\" > $CMDLINE_PATH"

    printSeparator
    grep 'video=' "$CMDLINE_PATH"
    printSeparator
    printComment 'Video modes added. A reboot is required for changes to take effect.' 'warning'
  fi
}

#-------------------------------------------------------------------------------
# Checks for the location of the "cmdline.txt" file on a Raspberry Pi. Returns 
# the path if found, or an empty string if not found.
#-------------------------------------------------------------------------------
checkPiCmdlineLocation () {
  local CMDLINE_PATH="/boot/firmware/cmdline.txt"
  local CMDLINE_ALT_PATH="/boot/cmdline.txt"

  local CMDLINE_PATH_TF="$(checkForFileOrDirectory "$CMDLINE_PATH")"
  local CMDLINE_ALT_PATH_TF="$(checkForFileOrDirectory "$CMDLINE_ALT_PATH")"

  if [ "$CMDLINE_PATH_TF" = true ]; then
    echo "$CMDLINE_PATH"
  elif [ "$CMDLINE_PATH_TF" = false ] && [ "$CMDLINE_ALT_PATH_TF" = true ]; then
    echo "$CMDLINE_ALT_PATH"
  else
    echo ""
  fi
}

setPiPowerOffOnHalt () {
  local MODEL="$(getRaspberryPiModel)"

  if [ "$MODEL" -le 3 ]; then
    printComment 'Raspberry Pi models 1, 2 or 3 do not have an EEPROM so "POWER_OFF_ON_HALT" cannot be set.' 'warning'

    return
  fi

  rpi-eeprom-config --edit | sed 's/POWER_OFF_ON_HALT=0/POWER_OFF_ON_HALT=1/' > /tmp/bootconf.txt

  if grep -q 'POWER_OFF_ON_HALT=1' /tmp/bootconf.txt; then
    rpi-eeprom-config --apply /tmp/bootconf.txt
    printComment "POWER_OFF_ON_HALT set to 1 in EEPROM config."

    rm /tmp/bootconf.txt

    printComment 'A reboot is required for changes to take effect.' 'warning'
  else
    printComment 'Failed to update POWER_OFF_ON_HALT.' 'error'

    rm /tmp/bootconf.txt

    return 1
  fi
}

#-------------------------------------------------------------------------------
# Updates the Raspberry Pi bootloader if the host machine is a Raspberry Pi 4 or
# newer.
#
# N.B.
# The function uses the "rpi-eeprom-update -a" command to apply any available
# updates. A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
updatePiBootloader () {
  local MODEL="$(getRaspberryPiModel)"

  if [ "$MODEL" -le 3 ]; then
    printComment 'Bootloader updates are not supported, or needed, on Raspberry Pi models 1, 2 or 3.' 'warning'

    return
  fi

  printComment "Updating Raspberry Pi bootloader…"
  printSeparator
  rpi-eeprom-update -a
  printSeparator

  if [ $? -eq 0 ]; then
    printComment 'Bootloader updated. A reboot is required for changes to take effect.' 'warning'
  else
    printComment 'Failed to update bootloader.' 'error'

    return 1
  fi
}

#-------------------------------------------------------------------------------
# Updates the Raspberry Pi firmware if the host machine is a Raspberry Pi 4 or
# newer.
#
# N.B.
# The function uses the "rpi-update" command to apply any available updates. A
# reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
updatePiFirmware () {
  local MODEL="$(getRaspberryPiModel)"

  if [ "$MODEL" -le 3 ]; then
    printComment 'Firmware updates are not required on Raspberry Pi models 1, 2 or 3.' 'warning'

    return
  fi

  printComment "Updating Raspberry Pi firmware…"
  printSeparator
  rpi-update
  printSeparator

  if [ $? -eq 0 ]; then
    printComment 'Firmware updated. A reboot is required for changes to take effect.' 'warning'
  else
    printComment 'Failed to update firmware.' 'error'

    return 1
  fi
}