# linshafun

Linux Shared Functions for various setup scripts.

Variables _try_ to be as explicit and consistent as possible, for example:

* being explicit about whether something includes a path or is only a name, e.g. `FILE_NAME` or `DIR_NAME` vs `FILE_PATH` or `DIR_PATH`; and 
* using consistent abbreviations such as `DIR`, `CONF` and `VAR`.

Functions _try_ to use `verbValue` or `verbObject` as naming conventions, for example:

* `addFooBar` – adds a value to an existing object;
* `changeFooBar` – changes an already set value;
* `checkFooBar` – checks if a value or object exists;
* `commentFooBar` – comments a line in or out of a file;
* `compareFooBar` – compares a value with another value;
* `controlFooBar` – performs an action on a service, e.g. start, stop or restart;
* `copyFooBar` – copies an object;
* `createFooBar` – creates an object;
* `disableFooBar` – disables a feature in a config file;
* `generateFooBar` – generates a value or object automatically;
* `getFooBar` – asks the user for input to set a value, or gets a substring from an existing value or object;
* `initialiseFooBar` – sets up a script or feature before it runs;
* `listFooBar` – lists objects, or the contents of an object;
* `printFooBar` – prints output to the terminal;
* `readFooBar` – reads an already set value;
* `removeFooBar` – removes a value or object;
* `replaceFooBar` – replaces a value with another value;
* `setFooBar` – sets a value; and
* `updateFooBar` – updates installed software or firmware.

To make this setup as portable as possible all scripts are POSIX compliant, i.e. they use `#!/bin/sh` not `#!/bin/bash`, with some cheeky liberties taken for readability – usually using `local` variable declarations within functions for readability.

*N.B.*
Most functions check the status of the commands they run. If a command fails, its own error is shown, the function prints an error saying what failed, and returns 1. The calling script decides what happens next.

Functions named `checkFooBar`, e.g. `checkForPackage`, return 0 or 1 and print nothing, so they can be used directly in `if checkFooBar; then`. Functions named `checkFooAndBar`, e.g. `checkForAndCreateSshConfig`, check something and then act on it.

Options, e.g. `--warning` or `--recursive`, go before any other arguments, e.g. `printComment --warning 'Text.'` or `removeFilesOrDirectories --recursive "$DIR_PATH"`. A function returns 1 with an error for an option it doesn't know, or for one placed after the other arguments. A value that starts with `-` must follow `--`, e.g. `printComment -- "$TEXT"`.

Only `initialiseScript` and `rebootSystem` exit the script. Mandatory arguments are declared with `"${1:?}"`, so if one is missing the shell stops the script with status 2.