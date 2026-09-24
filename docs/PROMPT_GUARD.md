# Prompt Guard Architecture

All active workflows now use a split-prompt design.

## Why

If identity-preservation instructions live directly inside the normal editable prompt box, a user can accidentally delete them.

To prevent that, each workflow now builds the final prompt like this:

```text
SYSTEM PROMPT  +  USER PROMPT   -> FINAL POSITIVE PROMPT
SYSTEM NEGATIVE + USER NEGATIVE -> FINAL NEGATIVE PROMPT
```

## Daily use

Edit these nodes:
- `USER PROMPT — edit this`
- `USER NEGATIVE — optional`

Normally do **not** edit:
- `SYSTEM PROMPT — DO NOT EDIT`
- `SYSTEM NEGATIVE — DO NOT EDIT`

## Benefits

- identity rules stay in place;
- role separation for reference images stays in place;
- the workflow is safer for non-technical users;
- custom user intent remains flexible.
