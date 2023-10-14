# linshafun

Linux Shared Functions for various setup scripts.

Functions try to use `verbValue` or `verbObject` as naming conventions, for example:

* "addFooBar" – adds a value to an existing object
* "changeFooBar" - changes an already set value
* "checkFooBar" - checks if a value or object exists
* "createFooBar" - creates an object
* "generateFooBar" - generates a value or object automatically
* "getFooBar" - asks the user for input to set a value, or gets a substring from an existing value or object
* "readFooBar" - reads an already set value
* "setFooBar" - sets a value

To make this setup as portable as possible all scripts are POSIX compliant, i.e they use `#!/bin/sh` not `#!/bin/bash`, with some cheeky liberties taken for readability.

*N.B.*
There is little to no error checking within these scripts. I may get around to that one day.
