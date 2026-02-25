# Conventional Commits

## Why we use this
We follow conventional commits to:
- Keep commit history clean and readable
- Improve collaboration and code reviews
- Enable future automation (changelogs, release notes, CI rules)

---

## Format

<type>(scope): subject

Example:
feat(auth): tenant-aware jwt validation

---

## Rules

- Use lowercase for type and scope
- Keep subject short and clear (max ~72 characters)
- Use present tense (add, fix, update — not added, fixed)
- No period at the end
- One logical change per commit

---

## Types

- feat      → new feature
- fix       → bug fix
- docs      → documentation only changes
- refactor  → code restructuring without feature change
- test      → adding or updating tests
- chore     → maintenance (deps, config, repo setup)
- ci        → CI/CD related changes

---

## Example Commits

- feat(auth): add tenant-aware JWT validation
- fix(api): handle missing tenant header
- docs(standards): add branch naming rules
- chore(repo): bootstrap folder structure
- ci(terraform): add terraform validate workflow