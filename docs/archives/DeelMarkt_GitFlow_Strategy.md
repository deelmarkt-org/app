# DeelMarkt GitFlow Strategy

> **v1.0.0** · 2026-03-15 · Aligned with Google, Amazon & Netflix trunk-based practices

---

## Branch Architecture

```
feature/* ──→ dev ──→ main ──→ production
hotfix/*  ────────→ main ──→ production (+ cherry-pick to dev)
```

| Branch | Purpose | Protection |
|:-------|:--------|:-----------|
| `production` | Live code. Tagged releases only | 🔒 PR + approval + CI |
| `main` | Release-ready stable code | 🔒 PR + approval + CI |
| `dev` | Shared integration for all contributors | 🔒 PR + CI |
| `feature/*` `fix/*` `docs/*` `chore/*` | Short-lived work branches (hours–days) | None |
| `hotfix/*` | Emergency production fixes (hours) | None |

---

## Contributor Workflow

### 1. Start Work

```powershell
git checkout dev && git pull origin dev
git checkout -b feature/<descriptive-name>
```

### 2. Commit (Conventional Commits)

```powershell
git commit -m "feat(marketplace): add listing creation endpoint"
```

| Type | Purpose |
|:-----|:--------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `refactor` | Code improvement |
| `test` | Tests |
| `chore` | Tooling/config |

### 3. Stay Updated

```powershell
git fetch origin && git rebase origin/dev
git push --force-with-lease
```

### 4. Open PR → `dev`

- CI runs automatically (lint, type-check, tests, build)
- Request review from a team member
- **Squash-merge** after approval → delete branch

---

## Release & Deploy

| Step | Action | Method |
|:-----|:-------|:-------|
| Sprint release | PR: `dev` → `main` | Merge commit |
| Production deploy | PR: `main` → `production` | Merge commit + tag `vX.Y.Z` |

```powershell
# Tag after production merge
git checkout production && git pull origin production
git tag -a v1.0.0 -m "Release v1.0.0 — Sprint 1"
git push origin v1.0.0
```

---

## Hotfix Protocol

```powershell
git checkout main && git pull origin main
git checkout -b hotfix/<issue-name>
# Fix → commit → PR to main → merge → tag → deploy
# Then cherry-pick the fix into dev
git checkout dev && git cherry-pick <sha> && git push origin dev
```

---

## Merge Strategy

| Flow | Method | Why |
|:-----|:-------|:----|
| `feature/*` → `dev` | Squash merge | Clean, one-commit-per-feature history |
| `dev` → `main` | Merge commit | Preserves sprint boundary |
| `main` → `production` | Merge commit + tag | Preserves release history |

---

## Rules

> [!IMPORTANT]
> - **Never** commit directly to `dev`, `main`, or `production` — always use PRs
> - **Never** let feature branches live longer than a few days
> - **Never** commit secrets, `.env` files, or `node_modules`
> - **Never** force-push to permanent branches
> - **Always** use `rebase` (not merge) to update feature branches
> - **Always** use Conventional Commits format
> - **Always** delete feature branches after merge

---

> *Industry validated: Google (35K engineers, trunk-based), Amazon (small commits, continuous integration), Netflix (short-lived feature branches + PR reviews)*
