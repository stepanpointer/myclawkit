# myclawkit ⚡

**Starter kit for OpenClaw — skills, agent identity, and initial config in one shot.**

## What's included

- **25 ready-to-use skills** — research, debugging, writing, brainstorming, business analysis, and more
- **Agent identity** (SOUL.md + AGENTS.md) — personality, principles, and working rules your agent loads on every session
- **Config template** — a sensible `openclaw.json` base that avoids the blank-page problem

## Quick start

```bash
git clone https://github.com/stepanpointer/myclawkit.git
cd myclawkit
./install.sh
```

The script will:
1. Check that OpenClaw and Git are present
2. Create `~/.openclaw/openclaw.json` if it doesn't exist yet
3. Copy SOUL.md and AGENTS.md to your agent workspace
4. Install skills to `~/.openclaw/skills/`

Existing configs and skills are never overwritten.

## Skills

| Skill | What it does |
|-------|-------------|
| `deep-research-pro` | Multi-source web research with citations |
| `systematic-debugging` | Step-by-step root-cause debugging |
| `brainstorming` | Structured ideation sessions |
| `writing-plans` | Break any goal into actionable steps |
| `business-architect` | Business models, unit economics, lean canvas |
| `subagent-runner` | Spawn and manage parallel sub-agents |
| `subagent-coordinator` | Coordinate results from multiple sub-agents |
| `agent-builder` | Design and scaffold new persistent agents |
| `last30days` | Trend research across Reddit, X, OpenAI sources |
| `reddit` | Search and summarize Reddit threads |
| `weather` | Current weather and forecasts (no API key needed) |
| `audit-website` | SEO, UX, and security audit |
| `presentation` | Markdown → slides via Marp |
| `excalidraw` | Generate diagrams for Obsidian/Excalidraw |
| `tubescribe` | YouTube video → transcript + audio |
| `tweet-writer` | Viral tweets and threads |
| `social-card-gen` | Posts formatted for different platforms |
| `copywriter-agent` | Content in a defined voice and style |
| `creator-marketing` | Funnels, sales copy, growth strategy |
| `marketing-mode` | Switch agent into pure marketing mindset |
| `youtube-seo` | Titles, descriptions, and timestamps |
| `methodologist` | Structure knowledge into instructions and docs |
| `gog` | Gmail, Calendar, Drive, Sheets, Docs via CLI |

Install a single skill manually:
```bash
cp -r skills/deep-research-pro ~/.openclaw/skills/
```

## Config

The script creates `~/.openclaw/openclaw.json` with sensible defaults.
Edit it to add channel tokens, adjust security policies, or switch models.

Full reference: [docs.openclaw.ai/gateway/configuration-reference.md](https://docs.openclaw.ai/gateway/configuration-reference.md)

## Agent identity

Two files define who the agent is:

- **SOUL.md** — identity, values, and personality (installed to `~/myclawkit-workspace/`)
- **AGENTS.md** — working rules: memory, security, skill routing

Edit these files to personalize the agent for your use case.
OpenClaw loads them from the workspace path configured in `openclaw.json`.

## After installation

```bash
# Start OpenClaw
openclaw start

# Verify everything is healthy
openclaw doctor

# Check available skills
openclaw skills list
```
