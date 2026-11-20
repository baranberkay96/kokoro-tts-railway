#!/bin/bash
# Kokoro start (Railway).
# - CPU inference sees the host's cores, not the service's quota (STANDARD 8.15):
#   size OMP/MKL/OpenBLAS thread pools from /sys/fs/cgroup/cpu.max, capped.
# - API_KEYS (upstream setting) is built from KOKORO_API_KEY. An unusable key
#   locks the API with a random one instead of leaving it open (STANDARD 8.29).
set -u

log() { echo "[railway-start] $*"; }
warn() { echo "[railway-start] WARNING: $*" >&2; }

MAX_THREADS=8

threads=${KOKORO_THREADS:-auto}
case "$threads" in
'' | auto)
	quota=max period=100000
	read -r quota period </sys/fs/cgroup/cpu.max 2>/dev/null || true
	case "$quota" in
	'' | max | *[!0-9]*) threads=$(nproc 2>/dev/null || echo 2) ;;
	*) threads=$(((quota + period - 1) / period)) ;;
	esac
	[ "$threads" -ge 1 ] 2>/dev/null || threads=1
	[ "$threads" -le "$MAX_THREADS" ] || threads=$MAX_THREADS
	;;
*[!0-9]* | 0)
	warn "KOKORO_THREADS='$threads' is not a positive number; using 2"
	threads=2
	;;
esac
export OMP_NUM_THREADS=$threads MKL_NUM_THREADS=$threads OPENBLAS_NUM_THREADS=$threads NUMEXPR_NUM_THREADS=$threads
log "inference threads: $threads (cgroup quota based, cap $MAX_THREADS; override with KOKORO_THREADS)"

key=${KOKORO_API_KEY:-}
if [ "${#key}" -lt 16 ] || [ "${#key}" -gt 256 ] || [[ ! "$key" =~ ^[A-Za-z0-9._~-]+$ ]]; then
	warn "KOKORO_API_KEY is empty, shorter than 16 or longer than 256 characters, or has characters"
	warn "outside A-Z a-z 0-9 . _ ~ -. The API is LOCKED with a random key nobody knows."
	warn "Set KOKORO_API_KEY on the 'Kokoro TTS' service and redeploy both services."
	key=$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')
fi
export API_KEYS="[\"$key\"]"
unset key KOKORO_API_KEY

port=${PORT:-8880}
case "$port" in
'' | *[!0-9]*) warn "PORT='$port' is not a port number; using 8880"; port=8880 ;;
esac
export PORT=$port
# Single-worker uvicorn on :: would be IPv6-only and miss Railway's IPv4 healthcheck.
export HOST=0.0.0.0

cd /app || exit 1
log "Kokoro-FastAPI $(cat VERSION 2>/dev/null) on $HOST:$PORT, API key required"
exec ./entrypoint.sh
