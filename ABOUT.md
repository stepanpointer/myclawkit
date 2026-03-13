# About myclawkit

## What is myclawkit?

myclawkit is a starter kit that gives your OpenClaw agent a working foundation out of the box: a config file, an identity, and a set of skills — without spending an hour reading documentation.

OpenClaw is powerful but starts blank. myclawkit fills that blank with sensible defaults so you can start using your agent immediately, then customize from there.

---

## When to use myclawkit

**Use myclawkit if:**

- You're setting up OpenClaw for the first time and want something that works right away
- You want a curated skill library without building each skill from scratch
- You're deploying OpenClaw on a new server and need a repeatable baseline setup
- You want a starting point for agent personality and working rules (SOUL.md / AGENTS.md) that you can then edit

**Use manual configuration if:**

- You already have a working `openclaw.json` and just need to add one thing (a new channel, a model change) — just edit the file directly
- You have specific security or compliance requirements that need a handcrafted config
- You're building a custom skill from scratch — myclawkit doesn't help with skill development, only installation
- You need advanced setups: multi-agent routing, custom session policies, sandboxing, Tailscale — those require reading the [OpenClaw docs](https://docs.openclaw.ai) directly

---

## What myclawkit gives you

### 1. A working config (`~/.openclaw/openclaw.json`)

Generated on first run, never overwritten if it already exists. Sets your AI model, workspace path, timezone, and any channels you enable. It's a starting point, not a final answer — edit it freely.

### 2. Agent identity (SOUL.md + AGENTS.md)

Two files that OpenClaw loads into every session:

- **SOUL.md** defines who the agent is — values, personality, how it communicates
- **AGENTS.md** defines how it works — memory rules, security rules, which skills to use when

Without these, OpenClaw runs with a generic system prompt. With them, the agent has consistent behavior across sessions.

### 3. Skills (~/.openclaw/skills/)

25 pre-built skills covering the most common use cases: research, writing, debugging, business analysis, content creation, productivity tools. Each skill is a `SKILL.md` file — readable, editable, and self-contained.

Skills are installed alongside any skills you already have. Existing ones are never replaced.

---

## What myclawkit does NOT do

- It does not install OpenClaw — OpenClaw must already be on your system
- It does not configure advanced features (multi-agent, sandboxing, OAuth flows)
- It does not replace reading the docs for anything beyond the basics
- It does not manage updates — if you want a newer version of a skill, update it manually

---

## After myclawkit

Once installed, the natural next steps are:

1. Add tokens for your channels in `~/.openclaw/openclaw.json`
2. Edit `SOUL.md` to match your preferred agent personality
3. Update `AGENTS.md` with any domain-specific rules for your workflow
4. Browse and install additional skills from [ClawHub](https://docs.openclaw.ai/tools/clawhub.md)
5. Set up cron jobs, hooks, or webhooks for automation

The [OpenClaw documentation](https://docs.openclaw.ai) covers all of this in detail.
