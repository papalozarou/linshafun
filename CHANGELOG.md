# Changelog

## Unreleased – v2.0.0

- `initialiseCommentLogs` takes the log user as its mandatory third argument and an optional log group as its fourth. The maximum age moves to the fifth.
- `printComment` prints warnings and errors to stderr, not stdout. Regular comments stay on stdout. This stops them being captured with the output of functions called using "$(…)".
- `printComment` prints wildcards in a comment as written, e.g. `*.log`, instead of replacing them with matching file names. It no longer sets `CURRENT_LINE` and `WORD` in the calling script.
