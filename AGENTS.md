# Agent guidance for linshafun

linshafun is a hand-made library of POSIX shell functions, sourced by setup and maintenance scripts in other projects. It does not follow any shared `AGENTS.md` template. Changes must stay in the style of the existing code, and must not refactor or rewrite it to meet other standards.

Read `README.md` first. It sets out the variable naming, the `verbObject` function naming, POSIX compliance and the use of `local`.

## Scope

- There is little to no error checking, by design (README N.B.). Do not add error-handling layers, input validation or `set -e`.
- Where a function does report a failure, it prints an error with `printComment '…' 'error'`. Only `return 1` or `exit 1` where similar existing functions already do. The exceptions are `controlDockerService`, `controlDockerStack` and `controlRelatedDockerServices`, which return a failure status because callers need to know if a `docker compose` action failed.
- `local` is not POSIX, but is used throughout and supported by `sh`, `dash` and `bash`. Do not remove it.
- Scripts in other projects use this library as a git submodule, so treat function names and arguments as a public interface. Check callers in other projects before changing them.

## Structure

- Functions in each file are in alphabetical order.
- Global variables are declared at the top of a file and treated as constants. Only make a variable global if it must be read across functions, i.e. `COMMENT_LOG_PATH`.
- Indent with two spaces.

## Doc comments

Every function has a header comment in this format:

```sh
#-------------------------------------------------------------------------------
# Does something to a thing. Takes two arguments, one of which is mandatory:
#
# 1. "${1:?}" – the thing, including directory path; and
# 2. "${2:-7}" – the number of things, defaulting to 7.
#
# N.B.
# Anything non-obvious, such as why the code does something.
#-------------------------------------------------------------------------------
```

- Do not document dependencies on other linshafun files.
- Explain why, not what the code plainly does.

## Code

- Local variables are uppercase. Store check results in a `_TF` variable, i.e. `local LOG_DIR_TF="$(checkForFileOrDirectory "$LOG_DIR_PATH")"`.
- `check…` functions echo `true` or `false`. `get…` functions echo their result for the caller to capture with `$(…)`.
- All output goes through `printComment`, so it is consistent and can be logged.
- Use British English in comments and printed output.

## Commits

Commit messages are in the past tense and describe the change, i.e. "Added function to rotate comment logs".
