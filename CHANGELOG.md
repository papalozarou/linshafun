# Changelog

## v2.2.0 – 2026-10-24

### `host-information.sh`

- `getRaspberryPiModel` returns the model number for Compute Modules, e.g. "4" for "Raspberry Pi Compute Module 4". Previously it returned an empty string, so callers comparing the model with `-ge` printed "integer expression expected" and skipped steps for Pi 4 and 5 boards.

### `packages.sh`

- `checkForPackagesAndInstall` and `checkForPackagesAndRemove` return 1 if any package can't be installed or removed, after carrying on with the rest. Previously they always returned 0.

### `setup-config.sh`

- `checkForAndCreateSetupConfigFileAndDir` and `createSetupConfigFile` return 1 if the directory or file can't be created, or if the file's permissions or owner can't be set. `checkForAndCreateSetupConfigFileAndDir` doesn't list the directory when this happens. Previously both always returned 0.

### `ssh-config.sh`

- `addHostToSshConfig` takes an optional fifth argument, the name of the key file in `~/.ssh`, e.g. `addHostToSshConfig 'github.com' '' '' '' 'github'`. It defaults to the host name, as before.
- `addHostToSshConfig` returns 1 with the error "Failed to add host, …, to …." if the host can't be written, and returns 1 if the file's permissions or owner can't be set. Previously it always returned the status of `setOwner`.
- `checkForAndCreateSshConfig` returns 1 if the file can't be created, or if its permissions or owner can't be set. Previously it always returned 0. Its comment no longer says it adds a basic config, which it never did.

### `ssh-keys.sh`

- `checkForAndCreateAuthorizedKeys` returns 1 if the file can't be created, or if its permissions or owner can't be set. Previously it always returned 0.
- `generateSshKey` returns 1 if the permissions or owner of either key file can't be set. Previously it carried on and returned 0.

## v2.1.0 – 2026-10-24

### `files-directories.sh`

- `createDirectories` returns 1 if any directory or subdirectory can't be created, after carrying on with the rest. It skips the subdirectories of a directory it can't create, and doesn't list a directory it failed to create. Previously it always returned 0, tried to create the subdirectories anyway, and listed every path.
- `createSubDirectories` is added. It creates subdirectories in a directory and lists each one, and returns 1 if any can't be created. `createDirectories` uses it.

## v2.0.1 – 2026-10-24

### `docker-services.sh`

- `controlDockerService` and `controlDockerStack` comments name "$FLAGS" as the unquoted variable. Previously they named "$4" and "$3".

### `files-directories.sh`

- `copyAndAddPostfixToFiles`, `copyAndRemovePostfixFromFiles`, `createDirectories` and `listDirectories` comments name the unquoted variables, "$FILE_PATHS", "$DIR_PATHS" and "$SUB_DIR_NAMES". Previously they named "$FILES", "$DIR_PATH(S)", "$SUB_DIR_NAME(S)" and "$DIR", which don't exist.

## v2.0.0 – 2026-10-24

### `archives.sh`

- `createTarArchive` takes `--date` before the other arguments, in place of `true` as the fourth argument.

### `comments-logs.sh`

- `createUserLogDir` is removed. `initialiseCommentLogs` creates the log directory's parent with `createDirectory`, with mode "700" and the log user as owner.
- `initialiseCommentLogs` takes the log file's full path as its first argument, in place of the log directory and log file name, the log user as its mandatory second argument and an optional log group as its third. The maximum age moves to the fourth.
- `initialiseCommentLogs` returns 1 with the error "Failed to create the log file at …. Logging is off for this run." if the log file can't be created. It clears `COMMENT_LOG_PATH`, so later comments print to the terminal only, and doesn't set the log directory's owner or permissions. Previously `COMMENT_LOG_PATH` stayed set, so every later comment also printed "cannot create … Directory nonexistent".
- `initialiseCommentLogs` sets "700" on the log directory and every directory in it, and "600" on every file in it. Previously every file was also set to "700", i.e. executable.
- `printCheckResult` is removed. Callers print "Checking …" with `printComment` and branch with `if checkFoo; then`. Previously it printed "Check returned true." or "Check returned false." and exited the script on any other value.
- `printComment` prints warnings and errors to stderr, not stdout. Regular comments stay on stdout. This stops them being captured with the output of functions called using "$(…)".
- `printComment` prints wildcards in a comment as written, e.g. `*.log`, instead of replacing them with matching file names. It no longer sets `CURRENT_LINE` and `WORD` in the calling script.
- `printComment` takes `--warning` or `--error` before the comment, in place of `'warning'` or `'error'` after it, e.g. `printComment --warning 'Text.'`. A comment that starts with `-` must follow `--`, e.g. `printComment -- "$TEXT"`. It returns 1 with an error for an unknown option, an option after the comment, both options, or more than one comment. Previously any second argument other than `warning` or `error` was ignored.
- `printScriptExiting` takes `--changes` in place of `true`, and returns 1 with an error if given any other argument.
- `readOptions` is added. It reads long options, e.g. `--warning`, from the start of a function's arguments.

### `crontab.sh`

- `addScriptToCron` no longer prints "Check returned true." or "Check returned false." after "Checking to see if …".
- `addScriptToCron` returns 1 with an error if the snippet can't be written, instead of exiting the script, and no longer prints "Checking to see if the snippet was created…". Previously it checked that the snippet file existed, so a failed write over an existing snippet reported success.
- `addScriptToCron` takes `--no-log` before the other arguments, in place of `false` as the fifth argument.
- `addScriptToCron` writes `\` in the command or script path as given. Previously dash's `echo` changed sequences such as `\n` into the characters they stand for.
- `checkForAndCreateUserLogDir` is removed. Use `createDirectory "$USER_LOG_DIR_PATH" '700' "$SUDO_USER"`.

### `docker-env-variables.sh`

- `changeDockerEnvVariable` no longer sets `ENV_VAR_SET_YN` in the calling script.
- `changeDockerEnvVariable` only looks up a value that is `$` followed by a valid variable name, e.g. `$HOST_DOMAIN`. Any other value starting with `$HOST` is shown as written. Previously the whole value was passed to `eval`, so `$HOST_X; cmd` ran `cmd`.
- `changeDockerEnvVariable` shows "(not set)" as the current value when the variable is blank, missing or names an unset host variable. Previously the script exited with status 2.
- `checkAndSetDockerEnvVariables` prints "H_A is set." or the warning "H_A is not set." instead of "Check returned true." or "Check returned false.".
- `checkAndSetDockerEnvVariables` and `compareAndUpdateDockerEnvVariables` no longer set `ENV_VAR` in the calling script.
- `checkAndSetDockerEnvVariables` and `compareAndUpdateDockerEnvVariables` exit the script with "1: parameter not set or null" if no variables are passed, or "ENV_VAR: parameter not set or null" if any are empty, before doing anything. Previously, with no variables they returned 0 and did nothing. An empty name stopped `checkAndSetDockerEnvVariables` partway through, and made `compareAndUpdateDockerEnvVariables` print "is not a valid variable name." and return 1.
- `checkIfDockerEnvVariableSet` returns 0 or 1 and prints nothing. Previously it printed `true` or `false`.
- `compareAndUpdateDockerEnvVariables` prints the error "H-A is not a valid variable name." for an invalid name, skips it and carries on. It returns 1 if any name was invalid or any change failed. Previously the name was passed to `eval` unchecked, so `H-A` was compared against `A`, and it returned the status of whatever ran last.
- `compareAndUpdateDockerEnvVariables` compares an empty comparison value with the file value. Previously the script exited with status 2.
- `compareDockerEnvVariableWithValue` is removed. `compareAndUpdateDockerEnvVariables` compares the value it has already read with `readDockerEnvVariable`.
- `readDockerEnvVariable` returns the whole value when it contains `=`, e.g. a base64 string ending in `==`. Previously the value was cut off at the second `=`.
- `readDockerEnvVariable` returns `\` in the value as given, and returns a value of `-n` instead of nothing. Previously dash's `echo` changed sequences such as `\n` into the characters they stand for.
- `readDockerEnvVariable` and `setDockerEnvVariable` only match a line that starts with the variable name, so `H_IP` no longer matches `C_PIH_IP=` or a commented-out `# H_IP=`. Previously the first line containing `H_IP=` was read, and `setDockerEnvVariable` overwrote every such line. A line starting with `export` or a space is no longer matched.
- `replaceDockerEnvPlaceholderVariable` returns 1 with the error "Failed to replace ${DKR_ENV: H_A} in …" if `sed` fails, e.g. the file doesn't exist. Previously it printed "Placeholder variable replaced." and returned 0.
- `replaceDockerEnvPlaceholderVariable` writes `&`, `|` and `\` in the value as given. Previously `&` was replaced with the placeholder, `|` made `sed` fail, and `\` was removed, so `a\b` was written as `ab`.
- `setDockerEnvVariable` returns 1 with the error "Failed to set H_A, as it was not found in …" if no line starts with `H_A=`, or "Failed to set H_A in …" if `sed` fails. Previously it printed "Variable updated." and returned 0 without writing anything. It still never adds a missing variable.
- `setDockerEnvVariable` writes `\` in the value as given. Previously it was removed, so `a\b` was written as `ab`, and `a\nb` was written as two lines.

### `docker-images.sh`

- `buildDockerImages` returns 1 if any image fails to build, after carrying on with the rest, and no longer prints "Assuming there are no errors above, the image was built.". `controlDockerService` reports each build's result. Previously it always returned 0.
- `buildDockerImages` and `removeDockerImages` no longer set `IMAGE` in the calling script.
- `buildDockerImages` and `removeDockerImages` exit the script with "1: parameter not set or null" if no images are passed, or "IMAGE: parameter not set or null" if any are empty, before doing anything. Previously, with no images they returned 0 and did nothing, and an empty image stopped the script after the images before it were built or removed.

### `docker-secrets.sh`

- `checkForAndCreateDockerSecretsDir` is removed. Use `createDirectory "$DKR_SECRETS_DIR_PATH" '600'`.
- `createDockerSecretFile` replaces an existing secret file instead of appending to it, writes the value with `printf` so values such as `-n` are written as given, lists the directory the file is in, and returns 1 with an error if the write fails. Previously a rerun gave a two-line secret, and a failed write reported success.
- `createDockerSecretFile` takes the secret file's full path. Previously a name without "/" was put in `$DKR_SECRETS_DIR_PATH`.
- `getAndSetDockerSecret`, `readDockerSecretFile` and `removeDockerSecretFile` take the secret file's full path. Previously `readDockerSecretFile` and `removeDockerSecretFile` added `$DKR_SECRETS_DIR_PATH/` in front of the name.
- `readDockerSecretFile` returns 1 with the error "Failed to read the secret file at …." if the file can't be read, and prints the file as written, so `\` in the value is kept. Previously it returned 0 with an empty value, and `a\nb` was printed as two lines.

### `docker-services.sh`

- `controlDockerStacks` and `controlRelatedDockerServices` exit the script with "1: parameter not set or null" if no stacks or services are passed, or "STACK_DIR_PATH: parameter not set or null" or "SERVICE: parameter not set or null" if any are empty, before doing anything. Previously, with none they returned 0 and did nothing. An empty stack path acted on the compose file in `$DKR_COMPOSE_FILE_PATH` instead and returned 0, and an empty service stopped the script after the services before it.
- `controlRelatedDockerServices` no longer sets `SERVICE` in the calling script.
- `getDockerComposeFilePath` returns `\` in the stack path as given. Previously dash's `echo` changed sequences such as `\n` into the characters they stand for.

### `docker-volumes.sh`

- `listDockerVolumeContents` and `manageDockerVolumes` no longer set `VOLUME` in the calling script.
- `listDockerVolumeContents` no longer lists the prefix as a volume, e.g. `listDockerVolumeContents Stack vol1` lists only `stack_vol1`. Previously it also listed `stack_Stack`. Called with no arguments, it exits the script after the error "shift: can't shift that many", as `manageDockerVolumes` does.
- `listDockerVolumeContents` prints the error "Failed to list the contents of stack_vol1." if `docker run` fails for a volume, carries on with the rest, and returns 1. Previously it returned 0.
- `listDockerVolumeContents` and `manageDockerVolumes` exit the script with "parameter not set or null" if the prefix is empty or missing. Previously they printed the error, carried on with an empty prefix, e.g. removed `_vol1`, and returned 0.
- `listDockerVolumeContents` and `manageDockerVolumes` exit the script with "1: parameter not set or null" if no volumes are passed, or "VOLUME_NAME: parameter not set or null" if any are empty, before doing anything. Previously, with no volumes they returned 0 and did nothing, and an empty volume acted on the prefix alone, e.g. created `stack_`, and returned 0.
- `manageDockerVolumes` passes the action unchanged for every volume. Previously it changed the action to sentence case after the first volume, so the rest ran `docker volume Rm …` without `-f` and failed. It no longer prints the debug line "rm and proj_".
- `manageDockerVolumes` prints the error "Rm failed on proj_vol1." if `docker volume` fails for a volume, carries on with the rest, and returns 1. Previously it printed "Rm performed on proj_vol1." and returned 0.

### `files-directories.sh`

- `checkAndCreateOrAskToReplaceFileOrDirectory` no longer prints "Check returned true." or "Check returned false.".
- `checkAndCreateOrAskToReplaceFileOrDirectory` takes `--replace` before the other arguments, in place of the action word as the third argument. Without it the prompt says "recreate". The warning moves from the fourth argument to the third.
- `checkForFileOrDirectory` returns 0 or 1 and prints nothing. Previously it printed `true` or `false`.
- `copyAndAddPostfixToFiles`, `copyAndRemovePostfixFromFiles`, `createFiles` and `removeFilesOrDirectories` return 1 if any file or directory fails, after carrying on with the rest. The copy and create functions print an error naming the file, and no longer print "File copied …" or "File created." after a failure. Previously all four returned 0.
- `copyAndAddPostfixToFiles`, `copyAndRemovePostfixFromFiles`, `createDirectories`, `createFiles`, `listDirectories` and `removeFilesOrDirectories` no longer set `DIR_PATH`, `FILE_OR_DIR_PATH`, `FILE_PATH`, `PARENT_DIR`, `SUB_DIR_NAME` or `SUB_DIR_PATH` in the calling script.
- `createDirectories` creates each directory path before its subdirectories.
- `createDirectory` takes optional permissions, owner and group as its second to fourth arguments, and sets them on the new directory only. If the directory exists, it returns 0 and prints nothing. It no longer creates missing parent directories: it returns 1 with an error if the parent doesn't exist, or if `mkdir`, `chmod` or `chown` fails. Previously it ran `mkdir -p`.
- `createFiles` exits the script with "1: parameter not set or null" if no files are passed, or "FILE_PATH: parameter not set or null" if any are empty, before doing anything. Previously, with no files it returned 0 and did nothing, and an empty path stopped the script after the files before it were created.
- `getListOfFilesByPostfix` and `getListOfFilesByPrefix` return `\` in file paths as given. Previously dash's `echo` changed sequences such as `\n` into the characters they stand for.
- `removeFileOrDirectory` is renamed to `removeFilesOrDirectories`, as it takes one or more paths.
- `removeFilesOrDirectories` removes files only, unless `--recursive` is passed first, e.g. `removeFilesOrDirectories --recursive "$DIR_PATH"`. Without it, a directory is left in place, the function prints an error and returns 1. Previously it always ran `rm -R`, so any directory was removed with its contents. Callers that remove directories must add `--recursive`.
- `removeFilesOrDirectories` returns 1 with an error, without removing anything, for an unknown option, e.g. `-R`, or an option after the paths. Previously a late `--recursive` was passed to `rm` as a path.
- `removeFilesOrDirectories` exits the script with "1: parameter not set or null" if no paths are passed, with or without `--recursive`, or "FILE_OR_DIR_PATH: parameter not set or null" if any are empty, before removing anything. Previously, with no paths it returned 0 and did nothing, and an empty path stopped the script after the paths before it were removed.
- `renameFileOrDirectory` prints an error if `mv` fails. It still returns 1.
- `renameFileOrDirectory` takes the current and new full paths, like `mv`. Previously it took a directory, defaulting to ".", then the current and new names.

### `firewall.sh`

- `addRuleToUfw` returns 1 with the error "Failed to add UFW rule "SSH": allow from any to any port 22 proto tcp." if `ufw` fails. Previously it printed "Rule added." and returned 0.
- `addRuleToUfw` takes five mandatory arguments, i.e. the action, source, port, protocol and comment, e.g. `addRuleToUfw 'allow' 'any' '53' 'any' 'Pi-hole DNS'`, and runs `ufw ACTION from SOURCE to any port PORT proto PROTOCOL comment COMMENT`. A source and protocol of "any" add the same rule as before. Previously it took an action, a port and an optional protocol, and ran `ufw ACTION PORT/PROTOCOL`, so a rule couldn't have a source or a comment.

### `host-env-variables.sh`

- `addHostEnvVariableToSudoersConf` and `setHostEnvVariable` write `\` in the variable name or value as given. Previously dash's `echo` changed sequences such as `\n` into the characters they stand for.
- `addHostEnvVariableToSudoersConf` writes to `SUDOERS_DEFAULT_CONF_PATH`, skips a line that's already there, checks the new line with `visudo` before adding it, sets the file's mode to 440, and returns 1 with an error on failure. Previously it wrote to the unset `SUDOERS_DEFAULT_CONF`, so it always failed.
- `checkForHostEnvVariable` returns 0 if the variable is present, 1 if not, or 2 if `PROFILE_PATH` can't be read, and prints nothing. Previously it printed `true` or `false`.
- `checkForHostEnvVariable` only matches a line starting with `export NAME=`, so `HOST_DOMAIN` no longer matches `HOST_DOMAIN_OLD`, `MY_HOST_DOMAIN` or a comment, and `setHostEnvVariable` adds the variable instead of reporting it as already added. A variable set any other way, e.g. `HOST_DOMAIN=x` then `export HOST_DOMAIN`, is no longer found, so `setHostEnvVariable` appends an `export` line.
- `setHostEnvVariable` returns 1 with the error "Failed to add H_A to …" if the `export` line can't be written. Previously it printed "H_A added." and returned 0.

### `host-information.sh`

- `checkIfRaspberryPi`, `checkIfRunAsUser`, `checkIfRunWithSudo`, `checkIfSystemRebooted` and `compareOsVersion` return 0 for true and non-zero for false, and print nothing. `checkIfRaspberryPi` returns 2 when `/proc/device-tree/model` doesn't exist and `checkIfSystemRebooted` returns 2 when the timeframe isn't a number; otherwise they return 0 or 1. Previously they printed `true` or `false`, so callers must use `if checkIfRaspberryPi; then` instead of comparing `"$(checkIfRaspberryPi)"`.
- `compareOsVersion` exits the script with "1: parameter not set or null" if the version is empty or missing. Previously it printed the error and "Illegal number", and returned 0.
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

- `checkAndCreateServiceFiles` no longer sets `FILE_NO_POSTFIX`, `FILE_PATH` or `FILE_W_POSTFIX` in the calling script.
- `createServiceFile` takes the service file's full path, without `.example`, and creates it from the matching `.example` file. Previously it took no arguments and used the `FILE_NO_POSTFIX` and `FILE_W_POSTFIX` globals set by `checkAndCreateServiceFiles`, so a direct call created whichever file was checked last.

### `linshafun.var`

- `PROFILE_PATH` holds one path: `~/.bashrc`, or `~/.bash_profile` if only that exists. Previously it held every `.bashrc` and `.bash_profile` anywhere under the home directory, so with more than one, `setHostEnvVariable` wrote nothing but reported success. With neither file, `~/.bashrc` is now created instead of the script exiting.

### `network.sh`

- `checkAgainstExistingPortNumber` returns 0 if the port matches the service's existing port and 1 if not, and prints nothing. Previously it printed `true` or `false`.
- `generateAndCheckPort` passes the service when it re-runs after a port clash. Previously the re-run failed and the calling script exited.
- `generateAndCheckPort` warns "Port 1234 is already used by rtt. Re-running to generate another port number." when it re-runs, instead of "Port check returned true. …".

### `ownership-permissions.sh`

- `setOwner` and `setPermissions` print an error if `chown` or `chmod` fails. They still return 1.
- `setPermissions` changes only the given path. `--recursive`, passed first, sets the first permissions on the directory and every directory in it, and the third on every file in it, e.g. `setPermissions --recursive '700' "$LOG_DIR_PATH" '600'`. Previously `chmod -R` gave the files and directories the same permissions.

### `packages.sh`

- `checkForPackage` checks whether the package is installed with `dpkg-query`, instead of whether a command with that name exists. A package that isn't a command, e.g. `openssh-server`, now reads as installed, and a command that isn't a package reads as not installed. A removed package whose config files remain reads as not installed. Callers must pass package names, e.g. `docker-ce`, not `docker`.
- `checkForPackage` returns 0 or 1 and prints nothing. Previously it printed `true` or `false`.
- `checkForPackagesAndInstall` and `checkForPackagesAndRemove` no longer print "Check returned true." or "Check returned false." after "Checking to see if … is installed…".
- `checkForPackagesAndInstall` and `checkForPackagesAndRemove` list every package passed. Previously only the first was listed.
- `checkForPackagesAndInstall`, `checkForPackagesAndRemove` and `managePackages` exit the script with "1: parameter not set or null" if no packages are passed, or "PACKAGE: parameter not set or null" if any are empty, before doing anything. Previously, with no packages the first two printed "Starting installation of the following packages:" (or removal) and then exited the script, and `managePackages` returned 0 and did nothing. An empty package stopped the first two partway through, and `managePackages` ran `apt install "" -y`.
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
- `addSetupVar` and `replaceSetupVar` take the setup variable file's full path. Previously they took the project name and wrote to `$SETUP_DIR_PATH/<name>-setup.var`.
- `checkForAndCreateSetupConfigFileAndDir` no longer prints "Check returned …" after each "Checking …" line.
- `createSetupConfigDirectory` is removed. `checkForAndCreateSetupConfigFileAndDir` calls `createDirectory` with `SUDO_USER` as owner.
- `readSetupConfigValue` matches the whole key, so `ssh` no longer matches `sshPort`. Values containing spaces or wildcards are returned as written. It no longer runs `set -f` in the calling script.
- `readSetupConfigValue` returns `\` in the value as given, and returns a value of `-n` instead of nothing. Previously dash's `echo` changed sequences such as `\n` into the characters they stand for, so `writeSetupConfigOption` rewrote an unchanged value containing `\` instead of printing "No changes made.".
- `reloadVarFile` takes the variable file's full path as a mandatory argument. Previously it defaulted to `$SETUP_VAR_PATH`, which nothing sets.
- `removeSetupConfigOption` and `writeSetupConfigOption` match the whole key, so `ssh` no longer matches `sshPort`. Previously `writeSetupConfigOption ssh on` overwrote the `sshPort` line, and `removeSetupConfigOption ssh` deleted it.
- `removeSetupConfigOption` returns 1 with the error "Failed to remove ssh from …" if `sed` fails. Previously it printed "ssh removed." and returned 0.
- `replaceSetupVar` no longer sets `VAR_FILE_NAME`, `VAR_FILE_PATH`, `VAR_NAME` or `VAR_VALUE` in the calling script.
- `replaceSetupVar` writes `\` in the value as given. Previously it was removed, so `a\b` was written as `ab`.
- `writeSetupConfigOption` no longer has a "Something went wrong" branch that exited the script. It couldn't be reached, as the key check only ever returned found or not found.
- `writeSetupConfigOption` returns 1 with the error "Failed to write ssh to …" if the option can't be written, and doesn't set the owner or list the setup config. Previously it printed "Config written." and returned 0.
- `writeSetupConfigOption` writes `\` in the value as given. Previously it was removed when overwriting an existing option, so `a\b` was written as `ab`, and a new option was written with dash's `echo`, which changed sequences such as `\n` into the characters they stand for.

### `setup.sh`

- `initialiseScript` prints "Checking the setup config to see if this step has already been performed…" whether or not the setup config file exists, and no longer prints "Check returned …". Its "Something went wrong" branch, which couldn't be reached, is removed.
- `initialiseScript` matches the whole key, so `ssh` no longer matches `sshPort`. Previously a step whose key was part of a longer key, e.g. `ssh` and `sshPort`, was treated as already performed.
- `initialiseScript` exits with status 0 when the step has already been performed. Previously it exited with status 1.

### `ssh-config.sh`

- `addHostToSshConfig` writes `\` in the host, address, port and user as given. Previously dash's `echo` changed sequences such as `\n` into the characters they stand for.
- `checkForAndCreateSshConfig` no longer prints "Check returned true." or "Check returned false.".
- `checkForAndCreateSshDir` is removed. Use `createDirectory "$SSH_DIR_PATH" '700' "$SUDO_USER"`.
- `printLocalSshConfig` prints `%` and `\` in the key file name, address, port and user as given. Previously a `%` caused a "printf: %\: invalid directive" error and ran the lines together, and `\` sequences such as `\n` were changed into the characters they stand for.

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

- `addPostfix`, `addPrefix`, `changeCase`, `getFirstCharsFromFirstLine`, `removePostfix` and `removePrefix` return `\` in the string as given, and return a string of `-n` instead of nothing. Previously dash's `echo` changed sequences such as `\n` into the characters they stand for.
- `checkFileContainsString` returns 0 if the string is found, 1 if not, or 2 if the file can't be read, and `checkStringContainsSubstring` returns 0 or 1. Both print nothing. Previously they printed `true` or `false`.
- `commentInLine` uncomments lines that use a comment character other than `#`, e.g. `;`. Previously it found the line, left it commented and reported success.
- `commentInLine` and `commentOutLine` accept `/` and `|` in the partial and the comment character. Previously `/` as the comment character made `sed` fail.
- `commentInLine` and `commentOutLine` match partials literally, so `\`, `[`, `.`, `*`, `^` and `$` are no longer treated as regular expression characters. Previously `[main]` matched any line starting with `m`, `a`, `i` or `n`.
- `commentInLine` and `commentOutLine` print the error "Failed to uncomment the line in …." or "Failed to comment out the line in …." and return 1 if `sed` can't change the line. Previously they printed no error and returned `sed`'s own status, e.g. 4.

### `user-input.sh`

- `getUserInputYN` returns 0 for y/Y and 1 for n/N, and prints nothing. Previously it printed `true` or `false`.

### `variables.sh`

- `checkIfValidVariableName` returns 0 or 1 and prints nothing. Previously it printed `true` or `false`.
- `verifyVariablesSet` exits the script with "1: parameter not set or null" if no names are passed, or "VAR_NAME: parameter not set or null" if any are empty, before checking anything. Previously, with no names it returned 0, and an empty name printed "is not a valid variable name." and returned 1.
