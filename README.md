# linshafun

Linux Shared Functions for various setup scripts.

Variables _try_ to be as explicit and consistent as possible, for example:

* being explicit about whether something includes a path or is only a name, e.g. `FILE_NAME` or `DIR_NAME` vs `FILE_PATH` or `DIR_PATH`; and 
* using consistent abbreviations such as `DIR`, `CONF` and `VAR`.

Functions _try_ to use `verbValue` or `verbObject` as naming conventions, for example:

* `addFooBar` – adds a value to an existing object;
* `buildFooBar` – builds an object from its definition, e.g. Docker images from a compose file;
* `changeFooBar` – changes an already set value;
* `checkFooBar` – checks if a value or object exists;
* `commentFooBar` – comments a line in or out of a file;
* `compareFooBar` – compares a value with another value;
* `confirmFooBar` – asks the user to confirm they have done something;
* `controlFooBar` – performs an action on a service, e.g. start, stop or restart;
* `copyFooBar` – copies an object;
* `createFooBar` – creates an object;
* `disableFooBar` – disables a feature in a config file;
* `enableFooBar` – enables a feature in a config file;
* `finaliseFooBar` – finishes a script or feature after it runs;
* `generateFooBar` – generates a value or object automatically;
* `getFooBar` – asks the user for input to set a value, or gets a substring from an existing value or object;
* `initialiseFooBar` – sets up a script or feature before it runs;
* `listFooBar` – lists objects, or the contents of an object;
* `manageFooBar` – performs a given action on one or more objects, e.g. install or remove;
* `printFooBar` – prints output to the terminal;
* `promptFooBar` – prints a question for the user to answer;
* `readFooBar` – reads an already set value, or the options passed to a function;
* `rebootFooBar` – reboots the system;
* `reloadFooBar` – loads an object again after it has changed, e.g. a variable file;
* `removeFooBar` – removes a value or object;
* `renameFooBar` – renames an object;
* `replaceFooBar` – replaces a value with another value;
* `rotateFooBar` – archives an object and starts a new one, e.g. a log;
* `setFooBar` – sets a value;
* `updateFooBar` – updates installed software or firmware;
* `verifyFooBar` – checks that values are set, printing an error for each one that isn't; and
* `writeFooBar` – writes a value to a file.

To make this setup as portable as possible all scripts are POSIX compliant, i.e. they use `#!/bin/sh` not `#!/bin/bash`, with some cheeky liberties taken for readability – usually using `local` variable declarations within functions for readability.

The shell syntax is POSIX, but some functions use GNU options, e.g. `sed -i`, `grep -m`, `grep -P`, `stat -c` and `date -d`. They need GNU `sed`, `grep`, coreutils, findutils and `tar`, as on Debian, Ubuntu and Synology DSM. BusyBox, e.g. on Alpine, isn't supported: `readIpAddress` and `checkIfSystemRebooted` fail on it.

*N.B.*
Most functions check the status of the commands they run. If a command fails, its own error is shown, the function prints an error saying what failed, and returns 1. The calling script decides what happens next.

Once `initialiseCommentLogs` has run, everything printed with `printComment` is also written to the log, including warnings, errors and separators. Anything else, e.g. a command's own output and errors from `cat`, `grep` or `ls`, appears only in the terminal.

Functions named `checkFooBar`, e.g. `checkForPackage`, return 0 or 1 and print nothing, so they can be used directly in `if checkFooBar; then`. Functions named `checkFooAndBar`, e.g. `checkForAndCreateSshConfig`, check something and then act on it.

Options, e.g. `--warning` or `--recursive`, go before any other arguments, e.g. `printComment --warning 'Text.'` or `removeFilesOrDirectories --recursive "$DIR_PATH"`. A function returns 1 with an error for an option it doesn't know, or for one placed after the other arguments. A value that starts with `-` must follow `--`, e.g. `printComment -- "$TEXT"`.

Only `initialiseScript` and `rebootSystem` exit the script. Mandatory arguments are declared with `"${1:?}"`, so if one is missing the shell stops the script with status 2.

Most globals that functions read are set in `linshafun.var` and `linshafun-docker.var`. The calling project must set `SETUP_CONF_PATH`, the setup config file including directory path, e.g. in its own `.var` file. It is used by the functions in `setup-config.sh` and by `initialiseScript`.

Some functions set globals for the calling script to use:

* `getCronFilenames` sets `CRON_SCRIPT_NAME`, `CRON_SCRIPT_PATH` and `CRON_SNIPPET_NAME`, and `getCronSchedule` sets `CRON_SCHEDULE`. `addScriptToCron` uses `CRON_SCRIPT_PATH`, `CRON_SCHEDULE` and `CRON_SNIPPET_NAME` when the matching argument isn't passed;
* `getSshHostDetails` sets `SSH_HOST`, `SSH_HOSTNAME`, `SSH_PORT` and `SSH_USER`; and
* `getSshKeyDetails` sets `SSH_KEY_NAME`, `SSH_EMAIL` and `SSH_KEY_PATH`.