# Changelog

## Unreleased – v2.0.0

### `comments-logs.sh`

- `createUserLogDir` is removed. `initialiseCommentLogs` creates the log directory's parent with `createDirectory`, with mode "700" and the log user as owner.
- `initialiseCommentLogs` takes the log user as its mandatory third argument and an optional log group as its fourth. The maximum age moves to the fifth.
- `printCheckResult` is removed. Callers print "Checking …" with `printComment` and branch with `if checkFoo; then`. Previously it printed "Check returned true." or "Check returned false." and exited the script on any other value.
- `printComment` prints warnings and errors to stderr, not stdout. Regular comments stay on stdout. This stops them being captured with the output of functions called using "$(…)".
- `printComment` prints wildcards in a comment as written, e.g. `*.log`, instead of replacing them with matching file names. It no longer sets `CURRENT_LINE` and `WORD` in the calling script.

### `crontab.sh`

- `addScriptToCron` no longer prints "Check returned true." or "Check returned false." after "Checking to see if …".
- `addScriptToCron` returns 1 with an error if the snippet can't be written, instead of exiting the script, and no longer prints "Checking to see if the snippet was created…". Previously it checked that the snippet file existed, so a failed write over an existing snippet reported success.
- `checkForAndCreateUserLogDir` is removed. Use `createDirectory "$USER_LOG_DIR_PATH" '700' "$SUDO_USER"`.

### `docker-env-variables.sh`

- `changeDockerEnvVariable` no longer sets `ENV_VAR_SET_YN` in the calling script.
- `checkAndSetDockerEnvVariables` prints "H_A is set." or the warning "H_A is not set." instead of "Check returned true." or "Check returned false.".
- `checkIfDockerEnvVariableSet` and `compareDockerEnvVariableWithValue` return 0 or 1 and print nothing. Previously they printed `true` or `false`.
- `compareDockerEnvVariableWithValue` and `readDockerEnvVariable` return the whole value when it contains `=`, e.g. a base64 string ending in `==`. Previously the value was cut off at the second `=`.

### `docker-secrets.sh`

- `checkForAndCreateDockerSecretsDir` is removed. Use `createDirectory "$DKR_SECRETS_DIR_PATH" '600'`.
- `createDockerSecretFile` replaces an existing secret file instead of appending to it, writes the value with `printf` so values such as `-n` are written as given, lists the directory the file is in, and returns 1 with an error if the write fails. Previously a rerun gave a two-line secret, and a failed write reported success.

### `files-directories.sh`

- `checkAndCreateOrAskToReplaceFileOrDirectory` no longer prints "Check returned true." or "Check returned false.".
- `checkForFileOrDirectory` returns 0 or 1 and prints nothing. Previously it printed `true` or `false`.
- `copyAndAddPostfixToFiles`, `copyAndRemovePostfixFromFiles`, `createFiles` and `removeFileOrDirectory` return 1 if any file or directory fails, after carrying on with the rest. The copy and create functions print an error naming the file, and no longer print "File copied …" or "File created." after a failure. Previously all four returned 0.
- `createDirectories` creates each directory path before its subdirectories.
- `createDirectory` takes optional permissions, owner and group as its second to fourth arguments, and sets them on the new directory only. If the directory exists, it returns 0 and prints nothing. It no longer creates missing parent directories: it returns 1 with an error if the parent doesn't exist, or if `mkdir`, `chmod` or `chown` fails. Previously it ran `mkdir -p`.
- `renameFileOrDirectory` prints an error if `mv` fails. It still returns 1.

### `host-env-variables.sh`

- `addHostEnvVariableToSudoersConf` writes to `SUDOERS_DEFAULT_CONF_PATH`, skips a line that's already there, checks the new line with `visudo` before adding it, sets the file's mode to 440, and returns 1 with an error on failure. Previously it wrote to the unset `SUDOERS_DEFAULT_CONF`, so it always failed.
- `checkForHostEnvVariable` returns 0 if the variable is present, 1 if not, or 2 if `PROFILE_PATH` can't be read, and prints nothing. Previously it printed `true` or `false`.

### `host-information.sh`

- `checkIfRaspberryPi`, `checkIfRunAsUser`, `checkIfRunWithSudo`, `checkIfSystemRebooted` and `compareOsVersion` return 0 for true and non-zero for false, and print nothing. `checkIfRaspberryPi` returns 2 when `/proc/device-tree/model` doesn't exist and `checkIfSystemRebooted` returns 2 when the timeframe isn't a number; otherwise they return 0 or 1. Previously they printed `true` or `false`, so callers must use `if checkIfRaspberryPi; then` instead of comparing `"$(checkIfRaspberryPi)"`.

### `host-initialisation.sh`

- `disablePiLedsInConfigTxt` gets the Pi model itself instead of relying on the caller's `MODEL`. It supports models 3, 4 and 5, using `14` for models 3 and 4, and returns 1 with an error on any other model. Previously an unset `MODEL` or an unsupported model wrote `dtparam=eth_led0=` and `dtparam=eth_led1=` with no value and reported success.
- `enablePiPcieGen3InConfigTxt` returns 1 with an error below a Raspberry Pi 5. Previously it wrote the PCIe lines on any model.
- `setPiPowerOffOnHalt` saves and applies the change when `POWER_OFF_ON_HALT` is 0. Previously it printed the updated config, applied nothing and reported a failure. The temporary config file now has a random name from `mktemp` instead of `/tmp/bootconf.txt`.
- `updatePiBootloader` and `updatePiFirmware` return 1 and print an error when `rpi-eeprom-update` or `rpi-update` fails, without writing the setup config option. Previously they always reported success.

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
- `installRemovePackages` returns 1 with the error "Unknown action "update". Use "install" or "remove"." if the first argument isn't "install" or "remove". Previously it printed "Exiting script with no changes." and exited the script.

### `setup-config.sh`

- `addSetupVar` and `replaceSetupVar` return 1 instead of exiting the script when the variable can't be written or isn't found afterwards. They also check the status of the write, so a failed write is reported even when the variable is already in the file.
- `checkForAndCreateSetupConfigFileAndDir` no longer prints "Check returned …" after each "Checking …" line.
- `createSetupConfigDirectory` is removed. `checkForAndCreateSetupConfigFileAndDir` calls `createDirectory` with `SUDO_USER` as owner.
- `readSetupConfigValue` matches the whole key, so `ssh` no longer matches `sshPort`. Values containing spaces or wildcards are returned as written. It no longer runs `set -f` in the calling script.
- `removeSetupConfigOption` and `writeSetupConfigOption` match the whole key, so `ssh` no longer matches `sshPort`. Previously `writeSetupConfigOption ssh on` overwrote the `sshPort` line, and `removeSetupConfigOption ssh` deleted it.
- `writeSetupConfigOption` no longer has a "Something went wrong" branch that exited the script. It couldn't be reached, as the key check only ever returned found or not found.

### `setup.sh`

- `initialiseScript` prints "Checking the setup config to see if this step has already been performed…" whether or not the setup config file exists, and no longer prints "Check returned …". Its "Something went wrong" branch, which couldn't be reached, is removed.
- `initialiseScript` matches the whole key, so `ssh` no longer matches `sshPort`. Previously a step whose key was part of a longer key, e.g. `ssh` and `sshPort`, was treated as already performed.

### `ssh-config.sh`

- `checkForAndCreateSshConfig` no longer prints "Check returned true." or "Check returned false.".
- `checkForAndCreateSshDir` is removed. Use `createDirectory "$SSH_DIR_PATH" '700' "$SUDO_USER"`.

### `ssh-keys.sh`

- `addSshKeytoAgent` is removed. It passed the public key to `ssh-add`, so the key was never added. The agent it started was the calling script's own agent, so it couldn't be reached once the script exited. Point `IdentityFile` at the key in `~/.ssh/config` instead, e.g. with `addHostToSshConfig`.
- `checkForAndCreateAuthorizedKeys` no longer prints "Check returned true." or "Check returned false.".
- `checkPrivateSshKeyCopied` no longer sets `KEY_COPIED_YN` in the calling script.

### `text.sh`

- `checkFileContainsString` returns 0 if the string is found, 1 if not, or 2 if the file can't be read, and `checkStringContainsSubstring` returns 0 or 1. Both print nothing. Previously they printed `true` or `false`.
- `commentInLine` uncomments lines that use a comment character other than `#`, e.g. `;`. Previously it found the line, left it commented and reported success.
- `commentInLine` and `commentOutLine` accept `/` and `|` in the partial and the comment character. Previously `/` as the comment character made `sed` fail.
- `commentInLine` and `commentOutLine` match partials literally, so `\`, `[`, `.`, `*`, `^` and `$` are no longer treated as regular expression characters. Previously `[main]` matched any line starting with `m`, `a`, `i` or `n`.

### `user-input.sh`

- `getUserInputYN` returns 0 for y/Y and 1 for n/N, and prints nothing. Previously it printed `true` or `false`.

### `variables.sh`

- `checkIfValidVariableName` returns 0 or 1 and prints nothing. Previously it printed `true` or `false`.
