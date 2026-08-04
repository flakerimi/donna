#!/bin/sh
# Deploy Donna. Basepod wipes an app's stored env on deploy, so this script
# always re-applies env from ~/Harnes/.env + .api-token and restarts.
#
#   --seed-auth   also ship ~/Harnes/auth.json (from `harness login` on this
#                 Mac) as a first-boot Claude OAuth seed. The entrypoint only
#                 writes it when no credential file exists on /data yet.
set -e
cd "$(dirname "$0")"

SEED_AUTH_B64=""
if [ "${1:-}" = "--seed-auth" ]; then
  SEED_AUTH_B64="$(base64 -i "$HOME/Harnes/auth.json" | tr -d '\n')"
fi

bp deploy

set -a; . "$HOME/Harnes/.env"; set +a

# APNs push delivery (deliver target push:<profile>) — key content rides env
# as base64 so no file lands in the image.
APNS_KEY_B64="$(base64 -i "$HOME/Harnes/AuthKey_STGRH25HZB.p8" | tr -d '\n')"

# Donna's own Google WEB OAuth client (remote /integration google).
GCJ="$(cd "$(dirname "$0")" && pwd)/google-web-client.json"
GOOGLE_CLIENT_ID=$(GCJ="$GCJ" python3 -c 'import json,os;print(json.load(open(os.environ["GCJ"]))["web"]["client_id"])')
GOOGLE_CLIENT_SECRET=$(GCJ="$GCJ" python3 -c 'import json,os;print(json.load(open(os.environ["GCJ"]))["web"]["client_secret"])')

bp env set donna \
  GOOGLE_CLIENT_ID="$GOOGLE_CLIENT_ID" \
  GOOGLE_CLIENT_SECRET="$GOOGLE_CLIENT_SECRET" \
  HARNESS_PUBLIC_URL=https://donna.common.al \
  TELEGRAM_BOT_TOKEN="${DONNA_TELEGRAM_TOKEN:?set DONNA_TELEGRAM_TOKEN in ~/Harnes/.env}" \
  DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY" \
  MOONSHOT_API_KEY="$MOONSHOT_API_KEY" \
  FIREWORKS_API_KEY="$FIREWORKS_API_KEY" \
  MIMO_API_KEY="$MIMO_API_KEY" \
  MISTRAL_API_KEY="$MISTRAL_API_KEY" \
  OPENROUTER_API_KEY="$OPENROUTER_API_KEY" \
  HARNESS_API_TOKEN="$(cat .api-token)" \
  HARNESS_PROFILE=personal \
  OWNER_NAME=Flak \
  HARNESS_TELEGRAM_ALLOW=8137251922 \
  HARNESS_BASH=1 \
  APNS_KEY_B64="$APNS_KEY_B64" \
  APNS_KEY_ID=STGRH25HZB \
  APNS_TEAM_ID=9FHBCA6NT3 \
  APNS_TOPIC=al.basecode.harnessApp \
  PULSE_DELIVER=app:personal \
  PULSE_SPEC="daily 08:30" \
  REFLECT_DELIVER=app:personal \
  INBOX_DELIVER=app:personal \
  PROVIDER=kimi \
  HARNESS_FALLBACK_PROVIDERS="fireworks,mistral,openrouter" \
  ${SEED_AUTH_B64:+HARNESS_AUTH_SEED_B64="$SEED_AUTH_B64"} \
  TZ=Europe/Tirane >/dev/null

bp restart donna
echo "deployed + env applied + restarted ✓"
