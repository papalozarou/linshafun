# Changelog

## Unreleased – v2.0.0

### `comments-logs.sh`

- `initialiseCommentLogs` takes the log user as its mandatory third argument and an optional log group as its fourth. The maximum age moves to the fifth.
- `printComment` prints warnings and errors to stderr, not stdout. Regular comments stay on stdout. This stops them being captured with the output of functions called using "$(…)".
- `printComment` prints wildcards in a comment as written, e.g. `*.log`, instead of replacing them with matching file names. It no longer sets `CURRENT_LINE` and `WORD` in the calling script.

### `docker-secrets.sh`

- `createDockerSecretFile` replaces an existing secret file instead of appending to it, writes the value with `printf` so values such as `-n` are written as given, lists the directory the file is in, and returns 1 with an error if the write fails. Previously a rerun gave a two-line secret, and a failed write reported success.

### `host-env-variables.sh`

- `addHostEnvVariableToSudoersConf` writes to `SUDOERS_DEFAULT_CONF_PATH`, skips a line that's already there, checks the new line with `visudo` before adding it, sets the file's mode to 440, and returns 1 with an error on failure. Previously it wrote to the unset `SUDOERS_DEFAULT_CONF`, so it always failed.

### `host-initialisation.sh`

- `disablePiLedsInConfigTxt` gets the Pi model itself instead of relying on the caller's `MODEL`. It supports models 3, 4 and 5, using `14` for models 3 and 4, and returns 1 with an error on any other model. Previously an unset `MODEL` or an unsupported model wrote `dtparam=eth_led0=` and `dtparam=eth_led1=` with no value and reported success.
- `enablePiPcieGen3InConfigTxt` returns 1 with an error below a Raspberry Pi 5. Previously it wrote the PCIe lines on any model.
- `setPiPowerOffOnHalt` saves and applies the change when `POWER_OFF_ON_HALT` is 0. Previously it printed the updated config, applied nothing and reported a failure. The temporary config file now has a random name from `mktemp` instead of `/tmp/bootconf.txt`.
- `updatePiBootloader` and `updatePiFirmware` return 1 and print an error when `rpi-eeprom-update` or `rpi-update` fails, without writing the setup config option. Previously they always reported success.

### `network.sh`

- `generateAndCheckPort` passes the service when it re-runs after a port clash. Previously the re-run failed and the calling script exited.

### `setup-config.sh`

- `readSetupConfigValue` matches the whole key, so `ssh` no longer matches `sshPort`. Values containing spaces or wildcards are returned as written. It no longer runs `set -f` in the calling script.

### `ssh-keys.sh`

- `addSshKeytoAgent` is removed. It passed the public key to `ssh-add`, so the key was never added. The agent it started was the calling script's own agent, so it couldn't be reached once the script exited. Point `IdentityFile` at the key in `~/.ssh/config` instead, e.g. with `addHostToSshConfig`.
