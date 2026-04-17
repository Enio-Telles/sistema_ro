#!/bin/sh
# Attempt to create PR using gh with body file to avoid PowerShell quoting issues
gh pr create --title "chore: add runtime v2 integration tests and checklist for phases 05-08" --body-file docs/pr_body_for_api_readable.txt --head feature/phase-05-08 --base main --repo Enio-Telles/sistema_ro --confirm
