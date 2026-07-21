# Donna

The deployment of [harness](https://github.com/flakerimi/harness) that is Donna —
a personal always-on assistant on Basepod (`donna.common.al`). The harness is the
generic engine; this repo is one identity built on it: persona, skills, plugins,
and the image + deploy scripts that keep her running.

## Layout

- `profiles/personal.md` — who Donna is (persona, tier, delegation)
- `skills/` — her SKILL.md workflows (chief-of-staff, pulse, reflect, publish, …)
- `plugins/` — exec plugins baked into the image (`pdf`, `woulduse`)
- `Dockerfile` — installs a pinned harness release, bakes identity + skills + plugins;
  `/data` is the persistent volume (memory, sessions, schedules, auth)
- `entrypoint.sh` — installs the heartbeat, inbox watch, and nightly reflection
  (idempotently), then runs `harness daemon`
- `deploy.sh` — `bp deploy`, then re-applies env (Basepod wipes app env on deploy)
  and restarts

## Deploying

```sh
./deploy.sh
```

Needs `~/Harnes/.env` (provider keys + `DONNA_TELEGRAM_TOKEN`), the APNs `.p8`
key, and the two gitignored files here: `.api-token`, `google-web-client.json`.
