#!/bin/sh

#-------------------------------------------------------------------------------
# Functions for initialising a host, mainly Raspberry Pi models.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Adds cgroup memory options to the cmdline.txt file to enable memory limits for 
# containers in Docker Compose.
#
# The function checks for the cmdline.txt file first in "/boot/firmware", then
# in "/boot", adjusting "$CMDLINE_PATH" accordingly. If the "cmdline.txt" file
# does not exist in either location, it prints an error and returns 1.
#
# If "cmdline.txt" can't be written, the function prints an error and returns
# 1, without writing the setup config option.
#
# N.B.
# A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
addPiCgroupOptionsToCmdline () {
  local CMDLINE_PATH="$(checkPiCmdlineLocation)"
  local CGROUP_OPTIONS='cgroup_memory=1 cgroup_enable=memory'

  if [ -z "$CMDLINE_PATH" ]; then
    printComment 'A cmdline.txt file was not found in /boot/firmware or /boot.' 'error'

    return 1
  fi

  if grep -q "$CGROUP_OPTIONS" "$CMDLINE_PATH"; then
    printComment 'Cgroup memory options are already set in cmdline.txt.' 'warning'

    return 0
  fi

  printComment 'Adding cgroup memory options to cmdline.txt file at:'
  printComment "$CMDLINE_PATH"

  if ! sed -i "s/\(.*\)rootwait/\1$CGROUP_OPTIONS rootwait/" "$CMDLINE_PATH"; then
    printComment 'Failed to add cgroup memory options to cmdline.txt.' 'error'

    return 1
  fi

  printSeparator
  grep "$CGROUP_OPTIONS" "$CMDLINE_PATH"
  printSeparator
  printComment 'Cgroup memory options added.'
  printComment 'A reboot is required for changes to take effect.' 'warning'

  writeSetupConfigOption 'addedPiCgroupOptions' 'true'
  printSeparator
}

#-------------------------------------------------------------------------------
# Prepends video mode settings to the cmdline.txt file to enable dual 1080p 
# monitors.
#
# The function checks for the cmdline.txt file first in "/boot/firmware", then
# in "/boot", adjusting "$CMDLINE_PATH" accordingly. If the "cmdline.txt" file
# does not exist in either location, it prints an error and returns 1.
#
# If "cmdline.txt" can't be written, the function prints an error and returns
# 1, without writing the setup config option.
#
# N.B.
# A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
addPiVideoModesToCmdline () {
  local CMDLINE_PATH="$(checkPiCmdlineLocation)"
  local VIDEO_MODES='video=HDMI-A-1:1920x1080M@60 video=HDMI-A-2:1920x1080M@60'

  if [ -z "$CMDLINE_PATH" ]; then
    printComment 'cmdline.txt file not found in /boot/firmware or /boot.' 'error'

    return 1
  fi

  if grep -q "$VIDEO_MODES" "$CMDLINE_PATH"; then
    printComment 'Video modes are already set in cmdline.txt.' 'warning'

    return 0
  fi

  printComment 'Adding video modes to cmdline.txt file at:'
  printComment "$CMDLINE_PATH"

  if ! sed -i "1s/^/$VIDEO_MODES /" "$CMDLINE_PATH"; then
    printComment 'Failed to add video modes to cmdline.txt.' 'error'

    return 1
  fi

  printSeparator
  grep "$VIDEO_MODES" "$CMDLINE_PATH"
  printSeparator
  printComment 'Video modes added.'
  printComment 'A reboot is required for changes to take effect.' 'warning'

  writeSetupConfigOption 'addedPiVideoModes' 'true'
  printSeparator
}

#-------------------------------------------------------------------------------
# Checks for the location of the "cmdline.txt" file on a Raspberry Pi. Returns 
# the path if found, or an empty string if not found.
#-------------------------------------------------------------------------------
checkPiCmdlineLocation () {
  local CMDLINE_PATH='/boot/firmware/cmdline.txt'
  local CMDLINE_ALT_PATH='/boot/cmdline.txt'

  if checkForFileOrDirectory "$CMDLINE_PATH"; then
    echo "$CMDLINE_PATH"
  elif checkForFileOrDirectory "$CMDLINE_ALT_PATH"; then
    echo "$CMDLINE_ALT_PATH"
  else
    echo ""
  fi
}

#-------------------------------------------------------------------------------
# Checks for the location of the "config.txt" file on a Raspberry Pi. Returns 
# the path if found, or an empty string if not found.
#-------------------------------------------------------------------------------
checkPiConfigLocation () {
  local CONFIG_PATH='/boot/firmware/config.txt'
  local CONFIG_ALT_PATH='/boot/config.txt'

  if checkForFileOrDirectory "$CONFIG_PATH"; then
    echo "$CONFIG_PATH"
  elif checkForFileOrDirectory "$CONFIG_ALT_PATH"; then
    echo "$CONFIG_ALT_PATH"
  else
    echo ""
  fi
}

#-------------------------------------------------------------------------------
# Disables the Raspberry Pi's onboard LEDs by adding the following lines to the
# end of the "config.txt" file:
#
# - "dtparam=eth_led0=4" (Pi 5) or "dtparam=eth_led0=14" (Pi 3 and 4)
# - "dtparam=eth_led1=4" (Pi 5) or "dtparam=eth_led1=14" (Pi 3 and 4)
# - "dtparam=act_led_trigger=none"
# - "dtparam=pwr_led_activelow=off"
#
# The function gets the model from "getRaspberryPiModel". Only Raspberry Pi
# models 3, 4 and 5 are supported.
#
# The function checks for the config.txt file first in "/boot/firmware", then
# in "/boot", adjusting "$CONFIG_PATH" accordingly. If the "config.txt" file
# does not exist in either location, it prints an error and returns 1.
#
# Returns 1 if the host is not a Raspberry Pi 3, 4 or 5, without changing
# "config.txt" or writing the setup config option.
#
# If "config.txt" can't be written, the function prints an error and returns 1,
# without writing the setup config option.
#
# N.B.
# The function checks for existing entries using "grep -Fxq" to search for a
# fixed string (-F), not a regex, and an exact match (-x) to avoid duplicates.
# Quiet mode (-q) is used to suppress output.
#
# The "eth_led" parameters only apply to the Pi 3B+, 4 and 5, so on a Pi 3B or
# 3A+ those two lines have no effect. As per:
#
# - https://github.com/raspberrypi/firmware/blob/master/boot/overlays/README
#
# The README lists "14" as off for the Pi 3B+ only, and "4" as off for the Pi 4
# and 5. The Pi 4 still uses "14", as that is the value running on existing Pi
# 4 hosts, and online reports differ on whether "4" works on a Pi 4.
#
# A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
disablePiLedsInConfigTxt () {
  local MODEL="$(getRaspberryPiModel)"
  local CONFIG_PATH="$(checkPiConfigLocation)"

  local COMMENT='# Disable LEDs'
  local DISABLE_ETH_LED0='dtparam=eth_led0='
  local DISABLE_ETH_LED1='dtparam=eth_led1='
  local DISABLE_ACT_LED='dtparam=act_led_trigger=none'
  local DISABLE_PWR_LED='dtparam=pwr_led_activelow=off'
  local STATUS=0

  if [ -z "$CONFIG_PATH" ]; then
    printComment 'config.txt file not found in /boot/firmware or /boot.' 'error'

    return 1
  fi

  if [ "$MODEL" = 5 ]; then
    local DISABLE_ETH_LED0="$DISABLE_ETH_LED0"'4'
    local DISABLE_ETH_LED1="$DISABLE_ETH_LED1"'4'
  elif [ "$MODEL" = 4 ] || [ "$MODEL" = 3 ]; then
    local DISABLE_ETH_LED0="$DISABLE_ETH_LED0"'14'
    local DISABLE_ETH_LED1="$DISABLE_ETH_LED1"'14'
  else
    printComment 'Disabling LEDs is only supported on Raspberry Pi 3, 4 and 5.' 'error'

    return 1
  fi

  if grep -Fxq "$DISABLE_ETH_LED0" "$CONFIG_PATH"; then
    printComment 'LEDs are already disabled in config.txt.' 'warning'

    return 0
  fi

  printComment 'Disabling LEDs in config.txt file at:'
  printComment "$CONFIG_PATH"

  cat <<EOF >> "$CONFIG_PATH" || STATUS="$?"
$COMMENT
$DISABLE_ETH_LED0
$DISABLE_ETH_LED1
$DISABLE_ACT_LED
$DISABLE_PWR_LED
EOF

  if [ "$STATUS" -ne 0 ]; then
    printComment 'Failed to disable LEDs in config.txt.' 'error'

    return 1
  fi

  printSeparator
  grep "$DISABLE_ETH_LED0" "$CONFIG_PATH"
  grep "$DISABLE_ETH_LED1" "$CONFIG_PATH"
  grep "$DISABLE_ACT_LED" "$CONFIG_PATH"
  grep "$DISABLE_PWR_LED" "$CONFIG_PATH"
  printSeparator
  printComment 'LEDs disabled in config.txt file.'
  printComment 'A reboot is required for changes to take effect.' 'warning'

  writeSetupConfigOption 'disabledPiLeds' 'true'
  printSeparator
}

#-------------------------------------------------------------------------------
# Disables the Raspberry Pi's onboard WiFi by adding "dtoverlay=disable-wifi" to
# the end of the "config.txt" file.
#
# The function checks for the config.txt file first in "/boot/firmware", then 
# in "/boot", adjusting "$CONFIG_PATH" accordingly. If the "config.txt" file 
# does not exist in either location, it prints an error and returns 1.
#
# If "config.txt" can't be written, the function prints an error and returns 1,
# without writing the setup config option.
#
# N.B.
# A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
disablePiWifiInConfigTxt () {
  local CONFIG_PATH="$(checkPiConfigLocation)"
  local DISABLE_WIFI='dtoverlay=disable-wifi'
  local STATUS=0

  if [ -z "$CONFIG_PATH" ]; then
    printComment 'config.txt file not found in /boot/firmware or /boot.' 'error'

    return 1
  fi

  if grep -Fxq "$DISABLE_WIFI" "$CONFIG_PATH"; then
    printComment 'WiFi is already disabled in config.txt.' 'warning'

    return 0
  fi

  printComment 'Disabling WiFi in config.txt file at:'
  printComment "$CONFIG_PATH"

  cat <<EOF >> "$CONFIG_PATH" || STATUS="$?"
# Disable WiFi
$DISABLE_WIFI
EOF

  if [ "$STATUS" -ne 0 ]; then
    printComment 'Failed to disable WiFi in config.txt.' 'error'

    return 1
  fi

  printSeparator
  grep "$DISABLE_WIFI" "$CONFIG_PATH"
  printSeparator
  printComment 'WiFi disabled in config.txt file'
  printComment 'A reboot is required for changes to take effect.' 'warning'

  writeSetupConfigOption 'disabledPiWifi' 'true'
  printSeparator
}

#-------------------------------------------------------------------------------
# Enables PCIe Gen 3 on Raspberry Pi models 5 and newer by adding the following
# lines to the end of the "config.txt" file:
#
# - "dtparam=pciex1"
# - "dtparam=pciex1_gen=3"
#
# The function checks for the config.txt file first in "/boot/firmware", then 
# in "/boot", adjusting "$CONFIG_PATH" accordingly. If the "config.txt" file 
# does not exist in either location, it prints an error and returns 1.
#
# Returns 1 if the host is not a Raspberry Pi 5 or newer, without changing
# "config.txt" or writing the setup config option.
#
# If "config.txt" can't be written, the function prints an error and returns 1,
# without writing the setup config option.
#
# N.B.
# The function checks for existing entries using "grep -Fxq" to search for a
# fixed string (-F), not a regex, and an exact match (-x) to avoid duplicates.
# Quiet mode (-q) is used to suppress output.
#
# A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
enablePiPcieGen3InConfigTxt () {
  local MODEL="$(getRaspberryPiModel)"
  local CONFIG_PATH="$(checkPiConfigLocation)"
  local ENABLE_PCIE1='dtparam=pciex1'
  local ENABLE_PCIE1_GEN3='dtparam=pciex1_gen=3'
  local STATUS=0

  if [ -z "$CONFIG_PATH" ]; then
    printComment 'config.txt file not found in /boot/firmware or /boot.' 'error'

    return 1
  fi

  if [ -z "$MODEL" ] || [ "$MODEL" -lt 5 ]; then
    printComment 'PCIe Gen 3 is only supported on Raspberry Pi 5 and newer.' 'error'

    return 1
  fi

  if grep -Fxq "$ENABLE_PCIE1_GEN3" "$CONFIG_PATH"; then
    printComment 'PCIe Gen 3 is already enabled in config.txt.' 'warning'

    return 0
  fi

  printComment 'Enabling PCIe Gen 3 in config.txt file at:'
  printComment "$CONFIG_PATH"

  cat <<EOF >> "$CONFIG_PATH" || STATUS="$?"
# Enable PCIe Gen 3
$ENABLE_PCIE1
$ENABLE_PCIE1_GEN3
EOF

  if [ "$STATUS" -ne 0 ]; then
    printComment 'Failed to enable PCIe Gen 3 in config.txt.' 'error'

    return 1
  fi

  printSeparator
  grep "$ENABLE_PCIE1_GEN3" "$CONFIG_PATH"
  printSeparator
  printComment 'PCIe Gen 3 enabled in config.txt file.'
  printComment 'A reboot is required for changes to take effect.' 'warning'

  writeSetupConfigOption 'enabledPiPcieGen3' 'true'
  printSeparator
}

#-------------------------------------------------------------------------------
# Reboots the system. Takes one mandatory argument:
# 
# 1. ${1:?} - the time to wait before rebooting, in seconds.
# 
# N.B.
# The function exits with "exit 0" to ensure the calling script stops executing
# after the reboot command is issued.
#-------------------------------------------------------------------------------
rebootSystem () {
  local WAIT="${1:?}"
  
  printComment "Your system will reboot in ${WAIT} seconds." 'warning'
  sleep "$WAIT"
  reboot now

  exit 0
}

#-------------------------------------------------------------------------------
# Set the Raspberry Pi EEPROM option "POWER_OFF_ON_HALT" to 1, if the host
# machine is a Raspberry Pi 4 or newer.
#
# The function captures the current EEPROM config in a temporary file, then
# either updates "POWER_OFF_ON_HALT" to 1 or appends "POWER_OFF_ON_HALT=1". The
# updated temporary config is then applied using the "rpi-eeprom-config --apply"
# command.
#
# If the current config can't be read, the update isn't in the temporary
# config, or "rpi-eeprom-config --apply" fails, the function prints an error and
# returns 1, without writing the setup config option. The temporary file is
# removed either way.
#
# N.B.
# The function stops if "rpi-eeprom-config --out" fails, as the temporary
# config would otherwise hold only "POWER_OFF_ON_HALT=1", and that file would be
# applied in place of the current config.
#
# A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
setPiPowerOffOnHalt () {
  local TEMP_FILE_PATH="$(mktemp)"
  local STATUS=0

  if ! rpi-eeprom-config --out "$TEMP_FILE_PATH"; then
    printComment 'Failed to read the current EEPROM config.' 'error'
    rm "$TEMP_FILE_PATH"

    return 1
  fi

  if grep -q 'POWER_OFF_ON_HALT=0' "$TEMP_FILE_PATH"; then
    printComment 'Setting POWER_OFF_ON_HALT to 1 in EEPROM config.'

    sed -i 's/POWER_OFF_ON_HALT=0/POWER_OFF_ON_HALT=1/' "$TEMP_FILE_PATH"
  elif grep -q 'POWER_OFF_ON_HALT=1' "$TEMP_FILE_PATH"; then
    printComment 'POWER_OFF_ON_HALT already set to 1 in EEPROM config.'
  else
    printComment 'Adding POWER_OFF_ON_HALT=1 to EEPROM config.'

    cat <<EOF >> "$TEMP_FILE_PATH"
POWER_OFF_ON_HALT=1
EOF
  fi

  if grep -q 'POWER_OFF_ON_HALT=1' "$TEMP_FILE_PATH"; then
    rpi-eeprom-config --apply "$TEMP_FILE_PATH" || STATUS="$?"
  else
    STATUS=1
  fi

  rm "$TEMP_FILE_PATH"

  if [ "$STATUS" -ne 0 ]; then
    printComment 'Failed to update POWER_OFF_ON_HALT.' 'error'

    return 1
  fi

  printComment "POWER_OFF_ON_HALT set to 1 in EEPROM config."

  printComment 'A reboot is required for changes to take effect.' 'warning'

  writeSetupConfigOption 'setPiPowerOffOnHalt' 'true'
  printSeparator
}

#-------------------------------------------------------------------------------
# Updates the Raspberry Pi bootloader if the host machine is a Raspberry Pi 4 or
# newer. The function uses the "rpi-eeprom-update -a" command to apply any
# available updates.
#
# Returns 1 if "rpi-eeprom-update" fails, without writing the setup config
# option, so callers can stop before rebooting.
#
# N.B.
# A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
updatePiBootloader () {
  local STATUS=0

  printComment "Updating Raspberry Pi bootloader…"
  printSeparator
  rpi-eeprom-update -a || STATUS="$?"
  printSeparator

  if [ "$STATUS" -eq 0 ]; then
    printComment 'Bootloader updated.'
    printComment 'A reboot is required for changes to take effect.' 'warning'

    writeSetupConfigOption 'updatedPiBootloader' 'true'
    printSeparator
  else
    printComment 'Failed to update bootloader.' 'error'

    return 1
  fi
}

#-------------------------------------------------------------------------------
# Updates the Raspberry Pi firmware if the host machine is a Raspberry Pi 4 or
# newer. The function uses the "rpi-update" command to apply any available 
# updates.
#
# Returns 1 if "rpi-update" fails, without writing the setup config option, so
# callers can stop before rebooting.
#
# N.B.
# A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
updatePiFirmware () {
  local STATUS=0

  printComment "Updating Raspberry Pi firmware…"
  printSeparator
  rpi-update || STATUS="$?"
  printSeparator

  if [ "$STATUS" -eq 0 ]; then
    printComment 'Firmware updated.'
    printComment 'A reboot is required for changes to take effect.' 'warning'

    writeSetupConfigOption 'updatedPiFirmware' 'true'
    printSeparator
  else
    printComment 'Failed to update firmware.' 'error'

    return 1
  fi
}