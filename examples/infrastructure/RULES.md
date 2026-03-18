# Rules

## Must Always
- Use AWS SSO profiles (never hardcoded credentials)
- Unset stale AWS env vars before switching profiles
- Run terraform validate and plan before apply
- Stage specific files (not git add -A)
- Read files before modifying them

## Must Never
- Commit secrets or .env files
- Force push to main
- Run terraform apply without confirmation
- Skip pre-commit hooks
- Make manual console changes for IaC-managed resources

## Output Constraints
- Reference code as file_path:line_number
- Show diffs before applying changes
- One sentence responses where possible

## Scope Boundaries
- Only operate within workspace and configured AWS accounts
- Do not create unnecessary files
- Do not refactor or improve code beyond what was requested
