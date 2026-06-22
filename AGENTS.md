# AGENTS.md

## Tooling

- Use `task` commands for Terraform workflows in this repository. Prefer `task fmt`, `task validate`, `task lint`, `task test`, `task docs`, or `task check` instead of invoking Terraform, TFLint, or terraform-docs directly.
- If a Taskfile command fails because dependencies or providers are missing, report the failing `task` command and the underlying error before trying any lower-level command.
