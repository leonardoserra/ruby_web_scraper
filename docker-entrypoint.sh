#!/bin/sh
set -e

# Suppress harmless GTK warnings
export GTK_MODULES=
export NO_AT_BRIDGE=1

# Ensure output directory exists and is writable
mkdir -p /app/output

# Prepare Tor data directory (owned by root, since we run as root)
mkdir -p /var/lib/tor
chown -R root:root /var/lib/tor
chmod 700 /var/lib/tor

cat > /tmp/torrc <<TORRC
SOCKSPort 127.0.0.1:9050
ControlPort 127.0.0.1:9051
CookieAuthentication 1
DataDirectory /var/lib/tor
User root
TORRC

tor -f /tmp/torrc &
TOR_PID=$!

for i in $(seq 1 15); do
  if nc -z 127.0.0.1 9050 2>/dev/null; then
    break
  fi
  sleep 1
done

mkdir -p /etc/privoxy
cat > /tmp/privoxy.config <<PRIVOXY
listen-address  127.0.0.1:8118
forward-socks5t / 127.0.0.1:9050 .
PRIVOXY

privoxy --no-daemon /tmp/privoxy.config &
PRIVOXY_PID=$!

for i in $(seq 1 10); do
  if nc -z 127.0.0.1 8118 2>/dev/null; then
    break
  fi
  sleep 1
done

exec "$@"
