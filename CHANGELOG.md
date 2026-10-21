# Changelog

## Unreleased – v2.0.0

### `comments-logs.sh`

- `createUserLogDir` is removed. `initialiseCommentLogs` creates the log directory's parent with `createDirectory`, with mode "700" and the log user as owner.
- `initialiseCommentLogs` takes the log user as its mandatory third argument and an optional log group as its fourth. The maximum age moves to the fifth.
- `initialiseCommentLogs` returns 1 with the error "Failed to create the log file at …. Logging is off for this run." if the log file can't be created. It clears `COMMENT_LOG_PATH`, so later comments print to the terminal only, and doesn't set the log directory's owner or permissions. Previously `COMMENT_LOG_PATH` stayed set, so every later comment also printed "cannot create … Directory nonexistent".
- `printCheckResult` is removed. Callers print "Checking …" with `printComment` and branch with `if checkFoo; then`. Previously it printed "Check returned true." or "Check returned false." and exited the script on any other value.
- `printComment` prints warnings and errors to stderr, not stdout. Regular comments stay on stdout. This stops them being captured with the output of functions called using "$(…)".
- `printComment` prints wildcards in a comment as written, e.g. `*.log`, instead of replacing them with matching file names. It no longer sets `CURRENT_LINE` and `WORD` in the calling script.

### `crontab.sh`

- `addScriptToCron` no longer prints "Check returned true." or "Check returned false." after "Checking to see if …".
- `addScriptToCron` returns 1 with an error if the snippet can't be written, instead of exiting the script, and no longer prints "Checking to see if the snippet was created…". Previously it checked that the snippet file existed, so a failed write over an existing snippet reported success.
- `checkForAndCreateUserLogDir` is removed. Use `createDirectory "$USER_LOG_DIR_PATH" '700' "$SUDO_USER"`.

### `docker-env-variables.sh`

- `changeDockerEnvVariable` no longer sets `ENV_VAR_SET_YN` in the calling script.
- `changeDockerEnvVariable` only looks up a value that is `$` followed by a valid variable name, e.g. `$HOST_DOMAIN`. Any other value starting with `$HOST` is shown as written. Previously the whole value was passed to `eval`, so `$HOST_X; cmd` ran `cmd`.
- `changeDockerEnvVariable` shows "(not set)" as the current value when the variable is blank, missing or names an unset host variable. Previously the script exited with status 2.
- `checkAndSetDockerEnvVariables` prints "H_A is set." or the warning "H_A is not set." instead of "Check returned true." or "Check returned false.".
- `checkAndSetDockerEnvVariables` and `compareAndUpdateDockerEnvVariables` no longer set `ENV_VAR` in the calling script.
- `checkIfDockerEnvVariableSet` returns 0 or 1 and prints nothing. Previously it printed `true` or `false`.
- `compareAndUpdateDockerEnvVariables` prints the error "H-A is not a valid variable name." for an invalid name, skips it and carries on. It returns 1 if any name was invalid or any change failed. Previously the name was passed to `eval` unchecked, so `H-A` was compared against `A`, and it returned the status of whatever ran last.
- `compareAndUpdateDockerEnvVariables` compares an empty comparison value with the file value. Previously the script exited with status 2.
- `compareDockerEnvVariableWithValue` is removed. `compareAndUpdateDockerEnvVariables` compares the value it has already read with `readDockerEnvVariable`.
- `readDockerEnvVariable` returns the whole value when it contains `=`, e.g. a base64 string ending in `==`. Previously the value was cut off at the second `=`.
- `readDockerEnvVariable` and `setDockerEnvVariable` only match a line that starts with the variable name, so `H_IP` no longer matches `C_PIH_IP=` or a commented-out `# H_IP=`. Previously the first line containing `H_IP=` was read, and `setDockerEnvVariable` overwrote every such line. A line starting with `export` or a space is no longer matched.
- `replaceDockerEnvPlaceholderVariable` returns 1 with the error "Failed to replace ${DKR_ENV: H_A} in …" if `sed` fails, e.g. the file doesn't exist. Previously it printed "Placeholder variable replaced." and returned 0.
- `replaceDockerEnvPlaceholderVariable` writes `&`, `|` and `\` in the value as given. Previously `&` was replaced with the placeholder, `|` made `sed` fail, and `\` was removed, so `a\b` was written as `ab`.
- `setDockerEnvVariable` returns 1 with the error "Failed to set H_A, as it was not found in …" if no line starts with `H_A=`, or "Failed to set H_A in …" if `sed` fails. Previously it printed "Variable updated." and returned 0 without writing anything. It still never adds a missing variable.
- `setDockerEnvVariable` writes `\` in the value as given. Previously it was removed, so `a\b` was written as `ab`, and `a\nb` was written as two lines.

### `docker-images.sh`

- `buildDockerImages` returns 1 if any image fails to build, after carrying on with the rest, and no longer prints "Assuming there are no errors above, the image was built.". `controlDockerService` reports each build's result. Previously it always returned 0.
- `buildDockerImages` and `removeDockerImages` no longer set `IMAGE` in the calling script.

### `docker-secrets.sh`

- `checkForAndCreateDockerSecretsDir` is removed. Use `createDirectory "$DKR_SECRETS_DIR_PATH" '600'`.
- `createDockerSecretFile` replaces an existing secret file instead of appending to it, writes the value with `printf` so values such as `-n` are written as given, lists the directory the file is in, and returns 1 with an error if the write fails. Previously a rerun gave a two-line secret, and a failed write reported success.

### `docker-services.sh`

- `controlRelatedDockerServices` no longer sets `SERVICE` in the calling script.

### `docker-volumes.sh`

- `listDockerVolumeContents` and `manageDockerVolumes` no longer set `VOLUME` in the calling script.
- `manageDockerVolumes` passes the action unchanged for every volume. Previously it changed the action to sentence case after the first volume, so the rest ran `docker volume Rm …` without `-f` and failed. It no longer prints the debug line "rm and proj_".
- `manageDockerVolumes` prints the error "Rm failed on proj_vol1." if `docker volume` fails for a volume, carries on with the rest, and returns 1. Previously it printed "Rm performed on proj_vol1." and returned 0.

### `files-directories.sh`

- `checkAndCreateOrAskToReplaceFileOrDirectory` no longer prints "Check returned true." or "Check returned false.".
- `checkForFileOrDirectory` returns 0 or 1 and prints nothing. Previously it printed `true` or `false`.
- `copyAndAddPostfixToFiles`, `copyAndRemovePostfixFromFiles`, `createFiles` and `removeFilesOrDirectories` return 1 if any file or directory fails, after carrying on with the rest. The copy and create functions print an error naming the file, and no longer print "File copied …" or "File created." after a failure. Previously all four returned 0.
- `copyAndAddPostfixToFiles`, `copyAndRemovePostfixFromFiles`, `createDirectories`, `createFiles`, `listDirectories` and `removeFilesOrDirectories` no longer set `DIR_PATH`, `FILE_OR_DIR_PATH`, `FILE_PATH`, `PARENT_DIR`, `SUB_DIR_NAME` or `SUB_DIR_PATH` in the calling script.
- `createDirectories` creates each directory path before its subdirectories.
- `createDirectory` takes optional permissions, owner and group as its second to fourth arguments, and sets them on the new directory only. If the directory exists, it returns 0 and prints nothing. It no longer creates missing parent directories: it returns 1 with an error if the parent doesn't exist, or if `mkdir`, `chmod` or `chown` fails. Previously it ran `mkdir -p`.
- `removeFileOrDirectory` is renamed to `removeFilesOrDirectories`, as it takes one or more paths.
- `removeFilesOrDirectories` removes files only, unless `--recursive` is passed first, e.g. `removeFilesOrDirectories --recursive "$DIR_PATH"`. Without it, a directory is left in place, the function prints an error and returns 1. Previously it always ran `rm -R`, so any directory was removed with its contents. Callers that remove directories must add `--recursive`.
- `renameFileOrDirectory` prints an error if `mv` fails. It still returns 1.

### `firewall.sh`

- `addRuleToUfw` returns 1 with the error "Failed to add rule allow 22 to UFW." if `ufw` fails. Previously it printed "Rule added." and returned 0.

### `host-env-variables.sh`

- `addHostEnvVariableToSudoersConf` writes to `SUDOERS_DEFAULT_CONF_PATH`, skips a line that's already there, checks the new line with `visudo` before adding it, sets the file's mode to 440, and returns 1 with an error on failure. Previously it wrote to the unset `SUDOERS_DEFAULT_CONF`, so it always failed.
- `checkForHostEnvVariable` returns 0 if the variable is present, 1 if not, or 2 if `PROFILE_PATH` can't be read, and prints nothing. Previously it printed `true` or `false`.
- `checkForHostEnvVariable` only matches a line starting with `export NAME=`, so `HOST_DOMAIN` no longer matches `HOST_DOMAIN_OLD`, `MY_HOST_DOMAIN` or a comment, and `setHostEnvVariable` adds the variable instead of reporting it as already added. A variable set any other way, e.g. `HOST_DOMAIN=x` then `export HOST_DOMAIN`, is no longer found, so `setHostEnvVariable` appends an `export` line.
- `setHostEnvVariable` returns 1 with the error "Failed to add H_A to …" if the `export` line can't be written. Previously it printed "H_A added." and returned 0.

### `host-information.sh`

- `checkIfRaspberryPi`, `checkIfRunAsUser`, `checkIfRunWithSudo`, `checkIfSystemRebooted` and `compareOsVersion` return 0 for true and non-zero for false, and print nothing. `checkIfRaspberryPi` returns 2 when `/proc/device-tree/model` doesn't exist and `checkIfSystemRebooted` returns 2 when the timeframe isn't a number; otherwise they return 0 or 1. Previously they printed `true` or `false`, so callers must use `if checkIfRaspberryPi; then` instead of comparing `"$(checkIfRaspberryPi)"`.
- `getKernalVersion` is renamed to `getKernelVersion`.

### `host-initialisation.sh`

- `addPiCgroupOptionsToCmdline`, `addPiVideoModesToCmdline`, `disablePiLedsInConfigTxt`, `disablePiWifiInConfigTxt` and `enablePiPcieGen3InConfigTxt` return 1 with an error, e.g. "Failed to disable WiFi in config.txt.", if `cmdline.txt` or `config.txt` can't be written, and don't write the setup config option. Previously they reported success and wrote the option as `true`, so a rerun skipped the step.
- `addPiCgroupOptionsToCmdline` and `addPiVideoModesToCmdline` edit `cmdline.txt` with `sed -i`. Previously they ran the edit through `sudo`, so they failed where `sudo` isn't installed.
- `checkPiCmdlineLocation` and `checkPiConfigLocation` are replaced by `getPiBootFilePath`, which takes the file name, e.g. `getPiBootFilePath 'config.txt'`.
- `disablePiLedsInConfigTxt` gets the Pi model itself instead of relying on the caller's `MODEL`. It supports models 3, 4 and 5, using `14` for models 3 and 4, and returns 1 with an error on any other model. Previously an unset `MODEL` or an unsupported model wrote `dtparam=eth_led0=` and `dtparam=eth_led1=` with no value and reported success.
- `enablePiPcieGen3InConfigTxt` returns 1 with an error below a Raspberry Pi 5. Previously it wrote the PCIe lines on any model.
- `setPiPowerOffOnHalt` saves and applies the change when `POWER_OFF_ON_HALT` is 0. Previously it printed the updated config, applied nothing and reported a failure. The temporary config file now has a random name from `mktemp` instead of `/tmp/bootconf.txt`.
- `setPiPowerOffOnHalt` returns 1 with the error "Failed to read the current EEPROM config." if `rpi-eeprom-config --out` fails, without applying anything. Previously it applied a config holding only `POWER_OFF_ON_HALT=1`. It also returns 1 with "Failed to update POWER_OFF_ON_HALT." if `--apply` fails or the update isn't in the temporary config, and doesn't write the setup config option. Previously it printed success after a failed apply, and returned 0 after its own failure message.
- `updatePiBootloader` and `updatePiFirmware` return 1 and print an error when `rpi-eeprom-update` or `rpi-update` fails, without writing the setup config option. Previously they always reported success.

### `initialisation.sh`

- `checkAndCreateServiceFiles` no longer sets `FILE_PATH` in the calling script.

### `linshafun.var`

- `PROFILE_PATH` holds one path: `~/.bashrc`, or `~/.bash_profile` if only that exists. Previously it held every `.bashrc` and `.bash_profile` anywhere under the home directory, so with more than one, `setHostEnvVariable` wrote nothing but reported success. With neither file, `~/.bashrc` is now created instead of the script exiting.

### `network.sh`

- `checkAgainstExistingPortNumber` returns 0 if the port matches the service's existing port and 1 if not, and prints nothing. Previously it printed `true` or `false`.
- `generateAndCheckPort` passes the service when it re-runs after a port clash. Previously the re-run failed and the calling script exited.
- `generateAndCheckPort` warns "Port 1234 is already used by rtt. Re-running to generate another port number." when it re-runs, instead of "Port check returned true. …".

### `ownership-permissions.sh`

- `setOwner` and `setPermissions` print an error if `chown` or `chmod` fails. They still return 1.

### `packages.sh`

- `checkForPackage` checks whether the package is installed with `dpkg-query`, instead of whether a command with that name exists. A package that isn't a command, e.g. `openssh-server`, now reads as installed, and a command that isn't a package reads as not installed. A removed package whose config files remain reads as not installed. Callers must pass package names, e.g. `docker-ce`, not `docker`.
- `checkForPackage` returns 0 or 1 and prints nothing. Previously it printed `true` or `false`.
- `checkForPackagesAndInstall` and `checkForPackagesAndRemove` no longer print "Check returned true." or "Check returned false." after "Checking to see if … is installed…".
- `checkForPackagesAndInstall`, `checkForPackagesAndRemove` and `managePackages` no longer set `PACKAGE` or `i` in the calling script.
- `installRemovePackages` is renamed to `managePackages`, to match `manageDockerVolumes`.
- `managePackages` returns 1 with the error "Unknown action "update". Use "install" or "remove"." if the first argument isn't "install" or "remove". Previously it printed "Exiting script with no changes." and exited the script.
- `managePackages` prints the error "Failed to install foo." if `apt` fails for a package, carries on with the rest, and returns 1. Previously it printed "Completed install for foo" and returned 0.
- `updateAndUpgradePackages` returns 1 with the error "Failed to update and upgrade packages." if `apt update` or `apt upgrade` fails. Previously it printed "Packages updated and upgraded." and returned 0.
- `updateUpgrade` is renamed to `updateAndUpgradePackages`.

### `services.sh`

- `controlService` returns 1 with an error, e.g. "Restart failed for sshd.", if `systemctl` or `ufw` fails. Previously it printed "Restart performed for sshd." and returned 0. A "status" action on a stopped service now reports a failure, as `systemctl status` returns 3.

### `setup-config.sh`

- `addSetupVar` and `replaceSetupVar` return 1 instead of exiting the script when the variable can't be written or isn't found afterwards. They also check the status of the write, so a failed write is reported even when the variable is already in the file.
- `addSetupVar` and `replaceSetupVar` match the whole variable name, so `SETUP_CONF` no longer matches `SETUP_CONF_PATH`. `replaceSetupVar` returns 1 with an error if the variable isn't in the file. Previously it replaced every line starting with the name, e.g. `SETUP_CONF_PATH_OLD`, and reported success if any other line contained the name.
- `addSetupVar` and `replaceSetupVar` return 1 with the error "SETUP-CONF-PATH is not a valid variable name." if the name isn't a valid variable name, without writing anything. Previously the name was written to the file, and sourcing it ran the name as a command, while the function reported the variable as added.
- `checkForAndCreateSetupConfigFileAndDir` no longer prints "Check returned …" after each "Checking …" line.
- `createSetupConfigDirectory` is removed. `checkForAndCreateSetupConfigFileAndDir` calls `createDirectory` with `SUDO_USER` as owner.
- `readSetupConfigValue` matches the whole key, so `ssh` no longer matches `sshPort`. Values containing spaces or wildcards are returned as written. It no longer runs `set -f` in the calling script.
- `removeSetupConfigOption` and `writeSetupConfigOption` match the whole key, so `ssh` no longer matches `sshPort`. Previously `writeSetupConfigOption ssh on` overwrote the `sshPort` line, and `removeSetupConfigOption ssh` deleted it.
- `removeSetupConfigOption` returns 1 with the error "Failed to remove ssh from …" if `sed` fails. Previously it printed "ssh removed." and returned 0.
- `replaceSetupVar` no longer sets `VAR_FILE_NAME`, `VAR_FILE_PATH`, `VAR_NAME` or `VAR_VALUE` in the calling script.
- `replaceSetupVar` writes `\` in the value as given. Previously it was removed, so `a\b` was written as `ab`.
- `writeSetupConfigOption` no longer has a "Something went wrong" branch that exited the script. It couldn't be reached, as the key check only ever returned found or not found.
- `writeSetupConfigOption` returns 1 with the error "Failed to write ssh to …" if the option can't be written, and doesn't set the owner or list the setup config. Previously it printed "Config written." and returned 0.
- `writeSetupConfigOption` writes `\` in the value as given when it overwrites an existing option. Previously it was removed, so `a\b` was written as `ab`. A new option is still written with `echo`, and dash's `echo` changes sequences such as `\n` into the characters they stand for.

### `setup.sh`

- `initialiseScript` prints "Checking the setup config to see if this step has already been performed…" whether or not the setup config file exists, and no longer prints "Check returned …". Its "Something went wrong" branch, which couldn't be reached, is removed.
- `initialiseScript` matches the whole key, so `ssh` no longer matches `sshPort`. Previously a step whose key was part of a longer key, e.g. `ssh` and `sshPort`, was treated as already performed.
- `initialiseScript` exits with status 0 when the step has already been performed. Previously it exited with status 1.

### `ssh-config.sh`

- `checkForAndCreateSshConfig` no longer prints "Check returned true." or "Check returned false.".
- `checkForAndCreateSshDir` is removed. Use `createDirectory "$SSH_DIR_PATH" '700' "$SUDO_USER"`.

### `ssh-keys.sh`

- `addKeyToAuthorizedKeys` returns 1 with the error "Failed to add the public key at …" if the public key can't be read or added. Previously it printed "Key added." and returned 0.
- `addSshKeytoAgent` is removed. It passed the public key to `ssh-add`, so the key was never added. The agent it started was the calling script's own agent, so it couldn't be reached once the script exited. Point `IdentityFile` at the key in `~/.ssh/config` instead, e.g. with `addHostToSshConfig`.
- `checkForAndCreateAuthorizedKeys` no longer prints "Check returned true." or "Check returned false.".
- `checkPrivateSshKeyCopied` and `checkPublicSshKeyCopied` are renamed to `confirmPrivateSshKeyCopied` and `confirmPublicSshKeyCopied`, as they ask the user to confirm instead of returning a status.
- `confirmPrivateSshKeyCopied` no longer sets `KEY_COPIED_YN` in the calling script.
- `confirmPrivateSshKeyCopied` removes the key with `removeFilesOrDirectories`, so it prints "Removing file or directory at:" and "File or directory removed.", and returns 1 with an error if the key can't be removed. Previously it printed "Private key removed." even when `rm` failed.
- `generateSshKey` returns 1 with the error "Failed to generate an ssh key at …" if `ssh-keygen` fails, e.g. when the overwrite prompt is answered "n", and doesn't set the key files' permissions or owner. Previously it printed "Key generated." and returned 0.
- `removePrivateSshKey` and `removePublicSshKey` are removed. Use `removeFilesOrDirectories`, e.g. `removeFilesOrDirectories "$KEY_PATH" "$KEY_PATH.pub"`.

### `text.sh`

- `checkFileContainsString` returns 0 if the string is found, 1 if not, or 2 if the file can't be read, and `checkStringContainsSubstring` returns 0 or 1. Both print nothing. Previously they printed `true` or `false`.
- `commentInLine` uncomments lines that use a comment character other than `#`, e.g. `;`. Previously it found the line, left it commented and reported success.
- `commentInLine` and `commentOutLine` accept `/` and `|` in the partial and the comment character. Previously `/` as the comment character made `sed` fail.
- `commentInLine` and `commentOutLine` match partials literally, so `\`, `[`, `.`, `*`, `^` and `$` are no longer treated as regular expression characters. Previously `[main]` matched any line starting with `m`, `a`, `i` or `n`.

### `user-input.sh`

- `getUserInputYN` returns 0 for y/Y and 1 for n/N, and prints nothing. Previously it printed `true` or `false`.

### `variables.sh`

- `checkIfValidVariableName` returns 0 or 1 and prints nothing. Previously it printed `true` or `false`.
