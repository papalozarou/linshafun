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
There is little to no error checking within these scripts. I may get around to that one day.