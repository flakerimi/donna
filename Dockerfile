# Donna — an always-on harness daemon.
# Build: installs the published harness module (pinned). Runtime: alpine with
# tzdata (schedules run in local time) and CA certs (providers, Telegram).

FROM golang:1.26-alpine AS build
RUN apk add --no-cache git
ARG HARNESS_VERSION=v0.20.0
RUN GOBIN=/out go install github.com/flakerimi/harness/cmd/harness@${HARNESS_VERSION}

FROM alpine:3.22
# curl + jq serve the exec plugins (shell-script integrations need them).
RUN apk add --no-cache ca-certificates tzdata curl jq poppler-utils
COPY --from=build /out/harness /usr/local/bin/harness

# /app holds the identity + skills + plugins baked into the image (redeploy to
# update); /data is the persistent volume: memory, sessions, schedule, tasks, auth.
WORKDIR /app
COPY profiles/ ./profiles/
COPY skills/ ./skills/
COPY plugins/ ./plugins/
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV XDG_CONFIG_HOME=/data
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
