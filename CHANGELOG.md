# Changelog

## Unreleased – v2.0.0

- `initialiseCommentLogs` takes the log user as its mandatory third argument and an optional log group as its fourth. The maximum age moves to the fifth.
- `printComment` prints warnings and errors to stderr, not stdout. Regular comments stay on stdout. This stops them being captured with the output of functions called using "$(…)".
- `printComment` prints wildcards in a comment as written, e.g. `*.log`, instead of replacing them with matching file names. It no longer sets `CURRENT_LINE` and `WORD` in the calling script.
- `readSetupConfigValue` matches the whole key, so `ssh` no longer matches `sshPort`. Values containing spaces or wildcards are returned as written. It no longer runs `set -f` in the calling script.
- `updatePiBootloader` and `updatePiFirmware` return 1 and print an error when `rpi-eeprom-update` or `rpi-update` fails, without writing the setup config option. Previously they always reported success.
- `generateAndCheckPort` passes the service when it re-runs after a port clash. Previously the re-run failed and the calling script exited.
