#!/usr/bin/env bash
# Termux IP changer (educational). Changes IP every INTERVAL seconds.
# Use at your own risk. Constantly changing IP can break network connectivity.
set -euo pipefail

# Usage:
#   ./ip_changer.sh [interval_seconds]
# or set INTERVAL env var
INTERVAL="${1:-${INTERVAL:-2}}"     # seconds between changes (default 2)
NETMASK=24                          # CIDR suffix e.g. /24
AVOID_LAST_OCTETS=(0 1 255)         # avoid gateway/broadcast-ish addresses
FALLBACK_PREFIX="192.168.43"        # fallback network prefix if none detected

# Ensure required command exists
if ! command -v ip >/dev/null 2>&1; then
  echo "🔴 'ip' command not found. Install iproute2 in Termux: pkg install iproute2" >&2
  exit 1
fi

# If not running as root, try to re-run via tsu (Termux)
if [ "$(id -u)" -ne 0 ]; then
  if command -v tsu >/dev/null 2>&1; then
    echo "ℹ️ Not root — re-execing with tsu..."
    # Re-run the same script as root (preserve args)
    exec tsu -c "bash \"$0\" $*"
  else
    echo "🔴 Root required and 'tsu' not found. Install tsu or run as root." >&2
    exit 1
  fi
fi

# Determine the default interface used for IPv4
IFACE=$(ip -4 route show default 2>/dev/null | awk '/default/ {print $5; exit}' || true)
if [ -z "$IFACE" ]; then
  echo "🔴 Could not find default network interface." >&2
  exit 1
fi
echo "ℹ️ Using interface: $IFACE"

# Capture the original IP/CIDR (if any) and default gateway to restore later
ORIG_IP_CIDR=$(ip -o -4 addr show dev "$IFACE" | awk '{print $4; exit}' || true)
ORIG_IP=${ORIG_IP_CIDR%%/*}
ORIG_GW=$(ip route show default dev "$IFACE" 2>/dev/null | awk '/default/ {print $3; exit}' || true)

echo "ℹ️ Original IP: ${ORIG_IP_CIDR:-(none)}"
if [ -n "$ORIG_GW" ]; then
  echo "ℹ️ Original gateway: $ORIG_GW"
fi

# Derive prefix from original IP if present, else use fallback
if [ -n "$ORIG_IP" ]; then
  PREFIX=$(echo "$ORIG_IP" | awk -F. '{print $1 "." $2 "." $3}')
else
  PREFIX="$FALLBACK_PREFIX"
  echo "⚠️ No existing IP found; falling back to prefix $PREFIX"
fi

# Helper: choose a random last octet avoiding reserved values
pick_last_octet() {
  while :; do
    # choose between 2..254 (avoids 0 and 1)
    candidate=$((RANDOM % 253 + 2))
    skip=false
    for v in "${AVOID_LAST_OCTETS[@]}"; do
      if [ "$candidate" -eq "$v" ]; then
        skip=true
        break
      fi
    done
    if ! $skip; then
      echo "$candidate"
      return
    fi
  done
}

# Restore original IP and route on exit
cleanup() {
  echo
  echo "🟡 Cleaning up..."
  # Remove all IPv4 addresses on interface
  ip addr flush dev "$IFACE" || true

  if [ -n "$ORIG_IP_CIDR" ]; then
    echo "🟢 Restoring original IP: $ORIG_IP_CIDR"
    ip addr add "$ORIG_IP_CIDR" dev "$IFACE" || true
  else
    echo "⚠️ No original IP to restore; interface $IFACE will be left without IPv4 address"
  fi

  # Restore gateway/default route if we captured one
  if [ -n "$ORIG_GW" ]; then
    echo "🟢 Restoring default route via $ORIG_GW"
    # delete any existing default routes on this interface first (best-effort)
    ip route del default dev "$IFACE" 2>/dev/null || true
    ip route add default via "$ORIG_GW" dev "$IFACE" 2>/dev/null || true
  fi

  exit 0
}
trap cleanup INT TERM

echo "▶️ Starting IP change loop on $IFACE (interval: ${INTERVAL}s). Press CTRL+C to stop."
while true; do
  LAST_OCTET=$(pick_last_octet)
  NEW_IP="${PREFIX}.${LAST_OCTET}"
  NEW_CIDR="${NEW_IP}/${NETMASK}"

  # Skip if identical to current primary IP
  if [ -n "$ORIG_IP" ] && [ "$NEW_IP" = "$ORIG_IP" ]; then
    # avoid immediately restoring the same address
    sleep 0.1
    continue
  fi

  echo "🟢 Setting IP: ${NEW_CIDR} on ${IFACE}"
  # Replace address: flush then add
  ip addr flush dev "$IFACE"
  ip addr add "$NEW_CIDR" dev "$IFACE"

  # Re-add the original gateway if present (some networks require explicit default route)
  if [ -n "$ORIG_GW" ]; then
    # delete any default route for this interface then add it back
    ip route del default dev "$IFACE" 2>/dev/null || true
    ip route add default via "$ORIG_GW" dev "$IFACE" 2>/dev/null || true
  fi

  sleep "${INTERVAL}"
done