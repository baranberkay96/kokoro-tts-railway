#!/bin/sh
# Gateway start (Railway): validates the sign-in variables, hashes the password
# (Caddy needs bcrypt) and runs Caddy. No deploy-form value stops the deploy:
# a missing or unusable password or key locks the site instead of opening it.
set -u

log() { echo "[railway-gateway] $*"; }
warn() { echo "[railway-gateway] WARNING: $*" >&2; }
random_token() { od -An -N24 -tx1 /dev/urandom | tr -d ' \n'; }

port="${PORT:-8080}"
case "$port" in
'' | *[!0-9]*) warn "PORT='$port' is not a port number; using 8080"; port=8080 ;;
esac
PORT=$port

user=${KOKORO_USERNAME:-}
case "$user" in
'' | *[!A-Za-z0-9._@-]*)
	warn "KOKORO_USERNAME='$user' is empty or has characters other than A-Z a-z 0-9 . _ @ -; using 'kokoro'"
	user=kokoro
	;;
esac
[ "${#user}" -le 64 ] || { warn "KOKORO_USERNAME is longer than 64 characters; using 'kokoro'"; user=kokoro; }

password=${KOKORO_PASSWORD:-}
if [ "${#password}" -lt 12 ] || [ "${#password}" -gt 72 ]; then
	# bcrypt uses at most 72 bytes; shorter than 12 is too easy to guess.
	password=$(random_token)
	warn "KOKORO_PASSWORD is empty, shorter than 12 or longer than 72 characters."
	warn "The web player is LOCKED with a random password nobody knows. Set KOKORO_PASSWORD"
	warn "(12-72 characters) on the Kokoro TTS service and redeploy it to sign in."
fi

key=${KOKORO_API_KEY:-}
case "$key" in
*[!A-Za-z0-9._~-]*) key= ;;
esac
if [ "${#key}" -lt 16 ] || [ "${#key}" -gt 256 ]; then
	# The kokoro service applies the same rule and locks its API, so a bad key
	# fails closed on both sides; the web player then gets 401s.
	warn "KOKORO_API_KEY is empty, shorter than 16 or longer than 256 characters, or has characters"
	warn "outside A-Z a-z 0-9 . _ ~ -. API calls and the web player fail until you fix it."
	key=$(random_token)
fi

upstream=${KOKORO_UPSTREAM:-}
if [ -z "$upstream" ]; then
	warn "KOKORO_UPSTREAM is empty; using kokoro.railway.internal:8880"
	upstream=kokoro.railway.internal:8880
fi

BASIC_AUTH_HASH=$(caddy hash-password --plaintext "$password") || {
	warn "caddy hash-password failed; locking the site with a random password"
	BASIC_AUTH_HASH=$(caddy hash-password --plaintext "$(random_token)")
}
unset KOKORO_PASSWORD password
BASIC_AUTH_USERNAME=$user
KOKORO_API_KEY=$key
KOKORO_UPSTREAM=$upstream
export PORT BASIC_AUTH_USERNAME BASIC_AUTH_HASH KOKORO_API_KEY KOKORO_UPSTREAM

log "web player sign-in for user $BASIC_AUTH_USERNAME; Kokoro at $KOKORO_UPSTREAM; port $PORT"
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
