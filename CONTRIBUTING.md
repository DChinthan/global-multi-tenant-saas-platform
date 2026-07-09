# Contributing

Thanks for your interest in improving this project. This is a reference/demo platform, so contributions of all sizes are welcome — from fixing a typo in the docs to adding a new Terraform module.

## Getting started

1. Fork the repo and clone your fork.
2. Create a branch off `main` using the naming convention in [`docs/standards/branches.md`](docs/standards/branches.md) (e.g. `feat/…`, `fix/…`, `docs/…`).
3. Make your change.
4. If you touched Terraform, run it through the standard checks before opening a PR:
   ```bash
   make tf-fmt
   make tf-validate ENV=dev
   make lint
   make sec
   ```
5. Commit using the [Conventional Commits](docs/standards/commits.md) format used throughout this repo's history (`feat:`, `fix:`, `docs:`, `chore:`, …) — releases are automated from these via `release-please`.
6. Open a pull request against `main` using the template in [`.github/PULL_REQUEST_TEMPLATE`](.github/PULL_REQUEST_TEMPLATE).

## Guidelines

- Keep changes scoped — small, focused PRs are much easier to review than large ones.
- Don't apply Terraform against real cloud accounts as part of a contribution; CI runs `validate`/`plan` only. New modules (like `eks` / `azure_aks`) should stay `terraform validate`-clean without requiring `apply`.
- If you add a feature that costs money when enabled, default it **off** (see the `enable_*` feature-flag pattern already used across `infra/terraform`).
- Update relevant docs (`README.md`, `HLD.md`/`LLD.md`, or `docs/`) alongside code changes.
- Be respectful and constructive in reviews and discussion — see the [Code of Conduct](CODE_OF_CONDUCT.md).

## Reporting bugs / requesting features

Open a GitHub issue with as much context as you can: what you expected, what happened, and steps to reproduce (Terraform version, environment, relevant logs/plan output).

## Security issues

Please do not open a public issue for a suspected security vulnerability. See [`docs/security/`](docs/security) for the project's threat model, and reach out to the maintainer directly first.
