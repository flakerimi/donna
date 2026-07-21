#!/bin/sh
# Assistant boot: install the heartbeat + nightly reflection (idempotently),
# then run the daemon. All state lives in /data (the persistent volume).
# Tenant-generic: every surface is driven by env, nothing personal baked in.
set -e

PROVIDER="${PROVIDER:-deepseek}"
OWNER="${OWNER_NAME:-the user}"

# Heartbeat: the pulse command is idempotent (stable id), so reinstall on
# every boot to pick up PULSE_* changes.
if [ -n "$PULSE_DELIVER" ]; then
  harness pulse -profile personal -provider "$PROVIDER" \
    -spec "${PULSE_SPEC:-daily 08:30}" -deliver "$PULSE_DELIVER" || true
fi

# Inbox watch: near-real-time email triage — check every few minutes, speak
# only when something deserves attention. Remove-then-add so prompt updates
# ship on redeploy. Only meaningful once Google is connected.
if [ -n "$INBOX_DELIVER" ]; then
  harness schedule remove inbox-personal 2>/dev/null || true
  harness schedule add -id inbox-personal -profile personal -provider "$PROVIDER" \
    -spec "${INBOX_SPEC:-every 10m}" -deliver "$INBOX_DELIVER" \
    "Inbox watch (runs every few minutes): check Gmail for unread messages from roughly the last 15 minutes. If any genuinely needs $OWNER's attention — a real person writing to them, something urgent or actionable — send one short line per message: who, what they want. Ignore newsletters, promos, automated notifications, receipts, and anything you've already reported. If nothing qualifies, reply with exactly the single word NOTHING (it is swallowed; no message is sent) — never any other phrasing." \
    2>/dev/null || true
fi

# Nightly reflection: distill the day's conversations into memory + skills.
# schedule add isn't idempotent, so guard with a marker in the volume.
if [ -n "$REFLECT_DELIVER" ] && [ ! -f /data/.reflect-installed ]; then
  harness schedule add -profile personal -provider "$PROVIDER" \
    -spec "${REFLECT_SPEC:-daily 23:30}" -deliver "$REFLECT_DELIVER" \
    "Run your reflect skill: load_skill reflect and follow it — review today's conversations and distill what's durable into memory and skills. Reply with a short 'what I learned today' note (2-4 bullets); if the day held nothing durable, output nothing at all." \
    && touch /data/.reflect-installed || true
fi

# Telegram only when a bot token is configured — app-first tenants run without.
TELEGRAM_FLAG=""
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
  TELEGRAM_FLAG="-telegram"
fi

exec harness daemon -provider "$PROVIDER" $TELEGRAM_FLAG -addr :8080
