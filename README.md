# linshafun

Linux Shared Functions for various setup scripts.

Variables _try_ to be as explicit and consistent as possible, for example:

* being explicit about whether something includes a path or is only a name, i.e. `FILE_NAME` or `DIR_NAME` vs `FILE_PATH` or `DIR_PATH`; and 
* using consistent abberviations such as `DIR`, `CONF` and `VAR`.

Functions _try_ to use `verbValue` or `verbObject` as naming conventions, for example:

* `addFooBar` – adds a value to an existing object;
* `changeFooBar` - changes an already set value;
* `checkFooBar` - checks if a value or object exists;
* `createFooBar` - creates an object;
* `generateFooBar` - generates a value or object automatically;
* `getFooBar` - asks the user for input to set a value, or gets a substring from an existing value or object;
* `readFooBar` - reads an already set value; and
* `setFooBar` - sets a value.

To make this setup as portable as possible all scripts are POSIX compliant, i.e they use `#!/bin/sh` not `#!/bin/bash`, with some cheeky liberties taken for readability – usually using `local` variable declarations within functions for readability.

*N.B.*
There is little to no error checking within these scripts. I may get around to that one day.