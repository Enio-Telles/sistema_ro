# PR #24 — chore(lint): add ruff, pre-commit and frontend ESLint + Prettier configs

## Summary

This PR adds repository-level linting and pre-commit enforcement to improve code quality and developer experience. Key goals:

- Add `ruff` integration and rules adjustments.
- Add and configure `.pre-commit-config.yaml` (ruff + basic hooks + frontend lint hook).
- Update CI to run lint (backend `ruff` + frontend `npm run lint`).
- Fix FastAPI `Path(regex=...)` deprecation by switching to `pattern=` where needed.
- Apply pre-commit auto-fixes (trailing whitespace, EOF) across the repo.
- Make frontend `eslint` hook cross-platform and relax `react/react-in-jsx-scope` to support modern JSX transform.
- Fix a small set of ruff-reported issues in Python source files.

## Files / changes of interest

- `pyproject.toml` — ruff config tweaks
- `.pre-commit-config.yaml` — hooks and frontend hook updated
- `.github/workflows/ci.yml` — lint job added
- `backend/app/routers_v5/pipeline.py` — `Path(pattern=...)` migration
- Large formatting commit: pre-commit auto-fixes applied across many files

## Reviewer checklist

- [ ] CI passes (pytest, vitest, ruff, frontend lint)
- [ ] Inspect mass formatting commit for unintended logic changes
- [ ] Confirm `pre-commit` runs locally on Linux and Windows for your dev setup
- [ ] Validate FastAPI Path change in `backend/app/routers_v5/pipeline.py`
- [ ] Approve that frontend eslint hook is now `language: node` in `.pre-commit-config.yaml`
- [ ] Merge after at least one approval and CI green
 - [ ] Verificar ausência de chaves/segredos no diff; incluir `.env.example` quando necessário.

## How to validate locally

Run these (from repo root):

```bash
python -m pip install --upgrade pip
python -m pip install pre-commit
pre-commit run --all-files
pytest -q
cd frontend
npm ci
npm test
npm run lint
```

## Notes / Risks

- The formatting commit touched many files; reviewers should focus on behavior-sensitive modules (backend services, SQL manifests).
- If CI identifies further `ruff` findings, fix and push to this branch; pre-commit will block local commits until resolved.
