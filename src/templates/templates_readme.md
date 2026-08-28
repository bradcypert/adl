# Templates and the Template Folder

The templates contained in this template folder will be used
if they are defined. If they are not defined, we will default
to the embedded templates used by the CLI.

This gives you the ability to customize your ADRs and READMEs
to meet your personal or team needs.

## Supported Template Filenames

### template_readme.md
This template is used to generate the README in the ADR folder.
It supports the following items.

| Field                 | Purpose        |
|-----------------------|--------------------------------------------------------------------------------|
| {{timestamp}}         | The timestamp at which the README was last generated|
| {{contents}}          | The contents of the ADR folder, structured as an ordered list, sorted by name. |

### template_adr.md
This template is used to generate a specific ADR.
It supports the following items:

| Field                | Purpose|
|-----------------------|-------------------------------|
| {{name}}              | The name of the generated ADR |