# Donna

Donna is a personal, always-on AI assistant: one named identity built on the
open-source [harness](https://github.com/flakerimi/harness) engine and run as a
single container. The engine is generic. This repository is what makes it
*Donna*: her persona, the skills she works from, the plugins baked into her
image, and the scripts that build, deploy and keep her running.

She is reached from her own phone app,
[donna-app](https://github.com/flakerimi/donna-app), which talks to the
engine's HTTP and SSE API. Scheduled work (a morning briefing, a periodic
pulse, a nightly reflection) is delivered to the app's inbox with a push
notification.

## What she does

The persona in `profiles/personal.md` sets the tone: lead with the answer,
remember what is durable about the person without being asked, anticipate,
do the work rather than describe it, and confirm before anything irreversible
or outward-facing. Everything longer than a few messages is published as a web
page and sent as a link rather than a wall of text.

The skills in `skills/` are the workflows she loads when one fits:

| Skill | When it is used |
|---|---|
| `chief-of-staff` | the morning briefing: today's calendar and overnight email, in one digest |
| `pulse` | the scheduled check-in that speaks only when something deserves attention |
| `reflect` | the nightly review of recent conversations, turned into durable memory and skills |
| `capture` | something forwarded to keep: a link, a quote, an idea, a person |
| `meeting-prep` | a briefing before a meeting, interview or call |
| `sanity-check` | an idea, deal or plan with numbers in it, before money or time is committed |
| `accountant` | receipts, expenses and spending summaries |
| `publish` | a long result as a styled web page plus a short summary |
| `dev-loop` | the edit, verify, commit loop when she changes code |
| `omnius` | the owner's media server |
| `haiku` | a haiku, in strict 5-7-5 |

`plugins/` holds two exec plugins built into the image: `pdf` (reading PDFs)
and `woulduse` (live stats for a product launch she watches).

## Layout

- `profiles/personal.md` — who Donna is: persona, model tier, delegation
- `skills/` — one folder per skill, each with a `SKILL.md`
- `plugins/` — exec plugins baked into the image
- `Dockerfile` — installs a pinned harness release and bakes in identity,
  skills and plugins; `/data` is the persistent volume (memory, sessions,
  schedules, auth)
- `entrypoint.sh` — installs the heartbeat, inbox watch and nightly reflection
  schedules (idempotently), then runs `harness daemon`
- `deploy.sh` — deploys the image, re-applies the environment and restarts
- `basepod.yaml` — the hosting definition
- `evals.md` — the behaviours she is checked against

## Running your own

Donna is one person's assistant, but the shape is reusable:

1. Fork this repository and rewrite `profiles/personal.md` for yourself.
2. Keep, drop or add skills under `skills/`. A skill is a folder with a
   `SKILL.md` whose front matter says when to use it.
3. Build the image with the `Dockerfile` and run it anywhere a container runs,
   with `/data` on persistent storage.
4. Point the [donna-app](https://github.com/flakerimi/donna-app) at your
   server's URL and API token.

The harness engine itself, its API and its providers are documented in the
[harness](https://github.com/flakerimi/harness) repository.

## Deploying this instance

```sh
./deploy.sh
```

Secrets are never in this repository. The script expects provider keys and
the Telegram token in `~/Harnes/.env`, the APNs `.p8` key beside it, and two
gitignored files here: `.api-token` and `google-web-client.json`.
