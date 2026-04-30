# DeelMarkt

> Trust-first Dutch P2P marketplace — a modern alternative to Marktplaats. _"Deel wat je hebt."_

**Domain:** deelmarkt.com | **Stack:** Flutter + Supabase + Mollie | **MVP cost: ~€25-35/mo**

---

## Quick Start

```bash
git clone <repo-url> DeelMarkt && cd DeelMarkt
bash scripts/setup.sh          # macOS/Linux
# or: .\scripts\setup.ps1      # Windows PowerShell
```

Then read [CLAUDE.md](CLAUDE.md) for development rules and start with [Epic E07](docs/epics/E07-infrastructure.md).

---

## Documentation

| Document                                | Purpose                                             |
| :-------------------------------------- | :-------------------------------------------------- |
| [CLAUDE.md](CLAUDE.md)                  | Development rules, architecture, coding standards   |
| [Setup Guide](docs/SETUP.md)            | Environment setup, prerequisites, troubleshooting   |
| [Sprint Plan](docs/SPRINT-PLAN.md)      | Per-developer tasks, ownership, conflict prevention |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Tech stack, backend, search, observability, ADRs    |
| [COMPLIANCE.md](docs/COMPLIANCE.md)     | Trust, security, GDPR, DSA, PSD2, legal             |
| [Design System](docs/design-system/)    | Tokens, components, patterns, accessibility         |
| [Epics](docs/epics/README.md)           | 8 development epics with acceptance criteria        |
| [ROADMAP.md](docs/ROADMAP.md)           | Phased timeline with KPIs                           |
| [CHANGELOG](docs/CHANGELOG.md)          | Version history                                     |

## AI-Powered Development

This project uses [Devran AI Kit](https://github.com/devran-ai/kit) for AI-assisted development. Open the project in your AI-powered IDE (VS Code + Copilot, Cursor, etc.) and use these commands:

### ⚡ Quick Start

`npx @devran-ai/kit init`

This automatically copies the `.agent/` folder to your project. Done!

| Command   | Purpose                                                                 |
| :-------- | :---------------------------------------------------------------------- |
| `/status` | Start a session — loads context and sprint state                        |
| `/plan`   | Plan a feature before building                                          |
| `/create` | Build a new feature from scratch                                        |
| `/review` | Run quality gates (lint, test, security)                                |
| `/help`   | **Full reference** — browse all commands, agents, skills, and workflows |

> **Tip**: Run `/help` anytime to explore the full AI Kit capabilities interactively.

---

## Tech Stack

| Layer                  | Service                | Cost    |
| :--------------------- | :--------------------- | :------ |
| Frontend               | Flutter 3.x + Dart 3.x | —       |
| Backend                | Supabase Pro           | $25/mo  |
| Payments               | Mollie Connect (iDEAL) | per-tx  |
| Feature Flags          | Unleash (self-hosted)  | $0-7/mo |
| Push/Crashes/Analytics | Firebase (free)        | $0      |
| CDN + WAF              | Cloudflare (free)      | $0      |
| Images                 | Cloudinary (free)      | $0      |
| Cache                  | Upstash Redis (free)   | $0      |

## Security

See [SECURITY.md](SECURITY.md) for our vulnerability disclosure policy, supported platforms, and coordinated disclosure timelines. Report security issues via [GitHub Security Advisories](https://github.com/deelmarkt-org/app/security/advisories/new) (preferred) or [security@deelmarkt.com](mailto:security@deelmarkt.com).

## License

All rights reserved.
