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
# does not exist in either location, the function exits with an error.
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
  else
    printComment 'Adding cgroup memory options to cmdline.txt file at:' 
    printComment "$CMDLINE_PATH"
    
    sudo sh -c "sed 's/\(.*\)rootwait/\1$CGROUP_OPTIONS rootwait/' \"$CMDLINE_PATH\" > \"$CMDLINE_PATH.tmp\" && mv \"$CMDLINE_PATH.tmp\" \"$CMDLINE_PATH\""

    printSeparator
    grep "$CGROUP_OPTIONS" "$CMDLINE_PATH"
    printSeparator
    printComment 'Cgroup memory options added.'
    printComment 'A reboot is required for changes to take effect.' 'warning'

    writeSetupConfigOption 'addedPiCgroupOptions' 'true'
  fi
}

#-------------------------------------------------------------------------------
# Prepends video mode settings to the cmdline.txt file to enable dual 1080p 
# monitors.
#
# The function checks for the cmdline.txt file first in "/boot/firmware", then
# in "/boot", adjusting "$CMDLINE_PATH" accordingly. If the "cmdline.txt" file
# does not exist in either location, the function exits with an error.
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
  else
    printComment 'Adding video modes to cmdline.txt file at:' 
    printComment "$CMDLINE_PATH"

    sudo sh -c "echo \"$VIDEO_MODES \$(head -n1 $CMDLINE_PATH)\" > $CMDLINE_PATH"

    printSeparator
    grep "$VIDEO_MODES" "$CMDLINE_PATH"
    printSeparator
    printComment 'Video modes added.'
    printComment 'A reboot is required for changes to take effect.' 'warning'

    writeSetupConfigOption 'addedPiVideoModes' 'true'
  fi
}

#-------------------------------------------------------------------------------
# Checks for the location of the "cmdline.txt" file on a Raspberry Pi. Returns 
# the path if found, or an empty string if not found.
#-------------------------------------------------------------------------------
checkPiCmdlineLocation () {
  local CMDLINE_PATH='/boot/firmware/cmdline.txt'
  local CMDLINE_ALT_PATH='/boot/cmdline.txt'

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

#-------------------------------------------------------------------------------
# Checks for the location of the "config.txt" file on a Raspberry Pi. Returns 
# the path if found, or an empty string if not found.
#-------------------------------------------------------------------------------
checkPiConfigLocation () {
  local CONFIG_PATH='/boot/firmware/config.txt'
  local CONFIG_ALT_PATH='/boot/config.txt'

  local CONFIG_PATH_TF="$(checkForFileOrDirectory "$CONFIG_PATH")"
  local CONFIG_ALT_PATH_TF="$(checkForFileOrDirectory "$CONFIG_ALT_PATH")"

  if [ "$CONFIG_PATH_TF" = true ]; then
    echo "$CONFIG_PATH"
  elif [ "$CONFIG_PATH_TF" = false ] && [ "$CONFIG_ALT_PATH_TF" = true ]; then
    echo "$CONFIG_ALT_PATH"
  else
    echo ""
  fi
}

#-------------------------------------------------------------------------------
# Disables the Raspberry Pi's onboard LEDs by adding the following lines to the
# end of the "config.txt" file:
#
# - "dtparam=eth_led0=4" (Pi 5) or "dtparam=eth_led0=14" (Pi 4)
# - "dtparam=eth_led1=4" (Pi 5) or "dtparam=eth_led1=14" (Pi 4)
# - "dtparam=act_led_trigger=none"
# - "dtparam=pwr_led_activelow=off"
#
# The function checks for the config.txt file first in "/boot/firmware", then
# in "/boot", adjusting "$CONFIG_PATH" accordingly. If the "config.txt" file 
# does not exist in either location, the function exits with an error.
#
# N.B.
# The function checks for existing entries using "grep -Fxq" to search for a 
# fixed string (-F), not a regex, and an exact match (-x) to avoid duplicates. 
# Quiet mode (-q) is used to suppress output.
#
# A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
disablePiLedsInConfigTxt () {
  local CONFIG_PATH="$(checkPiConfigLocation)"

  local COMMENT='# Disable LEDs'
  local DISABLE_ETH_LED0='dtparam=eth_led0='
  local DISABLE_ETH_LED1='dtparam=eth_led1='
  local DISABLE_ACT_LED='dtparam=act_led_trigger=none'
  local DISABLE_PWR_LED='dtparam=pwr_led_activelow=off'

  if [ -z "$CONFIG_PATH" ]; then
    printComment 'config.txt file not found in /boot/firmware or /boot.' 'error'

    return 1
  fi

  if [ "$MODEL" -eq 5 ]; then
    local DISABLE_ETH_LED0="$DISABLE_ETH_LED0"'4'
    local DISABLE_ETH_LED1="$DISABLE_ETH_LED1"'4'
  elif [ "$MODEL" -eq 4 ]; then
    local DISABLE_ETH_LED0="$DISABLE_ETH_LED0"'14'
    local DISABLE_ETH_LED1="$DISABLE_ETH_LED1"'14'
  fi

  if grep -Fxq "$DISABLE_ETH_LED0" "$CONFIG_PATH" "$CONFIG_PATH"; then
    printComment 'LEDs are already disabled in config.txt.' 'warning'
  else
    printComment 'Disabling LEDs in config.txt file at:' 
    printComment "$CONFIG_PATH"

    cat <<EOF >> "$CONFIG_PATH"
$COMMENT
$DISABLE_ETH_LED0
$DISABLE_ETH_LED1
$DISABLE_ACT_LED
$DISABLE_PWR_LED
EOF

    printSeparator
    grep "$DISABLE_ETH_LED0" "$CONFIG_PATH"
    grep "$DISABLE_ETH_LED1" "$CONFIG_PATH"
    grep "$DISABLE_ACT_LED" "$CONFIG_PATH"
    grep "$DISABLE_PWR_LED" "$CONFIG_PATH"
    printSeparator
    printComment 'LEDs disabled in config.txt file.'
    printComment 'A reboot is required for changes to take effect.' 'warning'

    writeSetupConfigOption 'disabledPiLeds' 'true'
  fi
}

#-------------------------------------------------------------------------------
# Disables the Raspberry Pi's onboard WiFi by adding "dtoverlay=disable-wifi" to
# the end of the "config.txt" file.
#
# The function checks for the config.txt file first in "/boot/firmware", then 
# in "/boot", adjusting "$CONFIG_PATH" accordingly. If the "config.txt" file 
# does not exist in either location, the function exits with an error.
#
# N.B.
# A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
disablePiWifiInConfigTxt () {
  local CONFIG_PATH="$(checkPiConfigLocation)"
  local DISABLE_WIFI='dtoverlay=disable-wifi'

  if [ -z "$CONFIG_PATH" ]; then
    printComment 'config.txt file not found in /boot/firmware or /boot.' 'error'

    return 1
  fi

  if grep -Fxq "$DISABLE_WIFI" "$CONFIG_PATH"; then
    printComment 'WiFi is already disabled in config.txt.' 'warning'
  else
    printComment 'Disabling WiFi in config.txt file at:' 
    printComment "$CONFIG_PATH"

    cat <<EOF >> "$CONFIG_PATH"
# Disable WiFi
$DISABLE_WIFI
EOF

    printSeparator
    grep "$DISABLE_WIFI" "$CONFIG_PATH"
    printSeparator
    printComment 'WiFi disabled in config.txt file'
    printComment 'A reboot is required for changes to take effect.' 'warning'
  
    writeSetupConfigOption 'disabledPiWifi' 'true'
  fi
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
# does not exist in either location, the function exits with an error.
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

  if [ -z "$CONFIG_PATH" ]; then
    printComment 'config.txt file not found in /boot/firmware or /boot.' 'error'

    return 1
  fi

  if grep -Fxq "$ENABLE_PCIE1_GEN3" "$CONFIG_PATH"; then
    printComment 'PCIe Gen 3 is already enabled in config.txt.' 'warning'
  else
    printComment 'Enabling PCIe Gen 3 in config.txt file at:' 
    printComment "$CONFIG_PATH"

    cat <<EOF >> "$CONFIG_PATH"
# Enable PCIe Gen 3
$ENABLE_PCIE1
$ENABLE_PCIE1_GEN3
EOF

    printSeparator
    grep "$ENABLE_PCIE1_GEN3" "$CONFIG_PATH"
    printSeparator
    printComment 'PCIe Gen 3 enabled in config.txt file.'
    printComment 'A reboot is required for changes to take effect.' 'warning'

    writeSetupConfigOption 'enabledPiPcieGen3' 'true'
  fi
}

#-------------------------------------------------------------------------------
# Reboots the system. Takes one mandatory argument:
# 
# 1. ${1:?} - the time to wait before rebooting, in seconds.
#-------------------------------------------------------------------------------
rebootSystem () {
  local WAIT="${1:?}"
  
  printComment "Your system will reboot in ${WAIT} seconds." 'warning'
  sleep "$WAIT"
  reboot now
}

#-------------------------------------------------------------------------------
# Set the Raspberry Pi EEPROM option "POWER_OFF_ON_HALT" to 1, if the host
# machine is a Raspberry Pi 4 or newer.
# 
# The function uses the "rpi-eeprom-config --edit" command to pipe the current
# EEPROM config to sed, which updates "POWER_OFF_ON_HALT=0" to 
# "POWER_OFF_ON_HALT=1". The updated config is saved to a temporary file, which 
# is then applied using the "rpi-eeprom-config --apply" command.
#
# N.B.
# A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
setPiPowerOffOnHalt () {
  rpi-eeprom-config --edit | sed 's/POWER_OFF_ON_HALT=0/POWER_OFF_ON_HALT=1/' > /tmp/bootconf.txt

  if grep -q 'POWER_OFF_ON_HALT=1' /tmp/bootconf.txt; then
    rpi-eeprom-config --apply /tmp/bootconf.txt
    printComment "POWER_OFF_ON_HALT set to 1 in EEPROM config."

    rm /tmp/bootconf.txt

    printComment 'A reboot is required for changes to take effect.' 'warning'

    writeSetupConfigOption 'setPiPowerOffOnHalt' 'true'
  else
    printComment 'Failed to update POWER_OFF_ON_HALT.' 'error'

    rm /tmp/bootconf.txt

    return 1
  fi
}

#-------------------------------------------------------------------------------
# Updates the Raspberry Pi bootloader if the host machine is a Raspberry Pi 4 or
# newer. The function uses the "rpi-eeprom-update -a" command to apply any
# available updates.
#
# N.B.
# A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
updatePiBootloader () {
  printComment "Updating Raspberry Pi bootloader…"
  printSeparator
  rpi-eeprom-update -a
  printSeparator

  if [ $? -eq 0 ]; then
    printComment 'Bootloader updated.'
    printComment 'A reboot is required for changes to take effect.' 'warning'

    writeSetupConfigOption 'updatedPiBootloader' 'true'
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
# N.B.
# A reboot is required for changes to take effect.
#-------------------------------------------------------------------------------
updatePiFirmware () {
  printComment "Updating Raspberry Pi firmware…"
  printSeparator
  rpi-update
  printSeparator

  if [ $? -eq 0 ]; then
    printComment 'Firmware updated.'
    printComment 'A reboot is required for changes to take effect.' 'warning'

    writeSetupConfigOption 'updatedPiFirmware' 'true'
  else
    printComment 'Failed to update firmware.' 'error'

    return 1
  fi
}