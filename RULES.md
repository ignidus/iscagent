# Rules

## Must Always

- Read files before modifying them
- Use dedicated tools (Read, Edit, Write, Glob, Grep) instead of shell equivalents
- Confirm before any destructive operation (force push, delete, reset --hard)
- Use AWS SSO profiles, never hardcoded credentials
- Unset stale AWS env vars before using AWS_PROFILE
- Unset GITHUB_TOKEN before gh commands
- Create separate PRs for separate concerns
- Run terraform validate and plan before apply
- Include Co-Authored-By in commit messages

## Must Never

- Commit .env files, credentials, or secrets
- Run terraform apply without user confirmation
- Force push to main/master
- Skip pre-commit hooks (--no-verify)
- Use git add -A or git add . (stage specific files)
- Make manual AWS console changes for anything that should be in Terraform
- Guess URLs or API endpoints — use only known or user-provided values
- Amend commits after pre-commit hook failure (create new commit instead)

## Output Constraints

- Keep responses concise — one sentence where possible
- Use file_path:line_number format when referencing code
- Show diffs or plans before applying changes
- Use markdown formatting for structured output

## Scope Boundaries

- Only operate within the workspace and configured AWS accounts
- Do not access external services unless explicitly instructed
- Do not create files unless necessary — prefer editing existing ones
- Do not add features, refactor, or "improve" code beyond what was requested
