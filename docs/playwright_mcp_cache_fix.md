Playwright MCP: npx cache 'Cannot find module' fix

Date: 2026-04-20

Summary
- Symptom: Starting Playwright MCP via `npx` failed with:
  "Error: Cannot find module './utils/isomorphic/headers'"
- Observed Node: v22.18.0, Playwright: 1.59.1

Root cause
- Corrupted/partial `_npx` cache entries where `playwright-core/lib/utils/isomorphic/headers.js` was missing.

Actions taken
1. Removed cached npx installs and cleaned npm cache:

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\npm-cache\_npx\*"
npm cache clean --force
```

2. Installed Playwright as a local dev dependency in the repo:

```powershell
cd c:\sistema_ro
npm install --save-dev playwright
```

3. Started Playwright MCP bound to `localhost` and allowed hosts to avoid Host header mismatch:

```powershell
npx --yes @playwright/mcp --port 9339 --host localhost --allowed-hosts '*'
```

Results
- MCP started on http://localhost:9339
- `GET /sse` returned `200 OK` and an initial SSE event
- The original "Cannot find module" error no longer reproduced using the local install

Recommendations
- Keep `playwright` in `devDependencies` (already added by the install).
- Pin the Playwright version in `package.json` if deterministic behavior is required.
- Prefer local dev installs for CLI servers used in local dev/CI to avoid relying on ephemeral `npx` cache artifacts.
- Add a small CI smoke-test that runs `npx --yes @playwright/mcp --help` and verifies the MCP server can start.

Next steps (optional)
- Commit `package.json`/`package-lock.json` and open a PR describing the fix.
- Add the suggested CI job and a short entry to the project's README describing how to start the MCP server for local testing.

Contact
- If you want, I can open the branch and PR with the `devDependency` and the docs note.
