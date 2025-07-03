#!/usr/bin/env bash

echo "nameserver 9.9.9.9" > /etc/resolv.conf

CFG=/etc/wg-wifi
WG_IFACE=wg0
SUBNET=${SUBNET:-192.168.77.0/24}

# ---------- 0  Sanity checks ----------
: "${WIFI_PSK:?Need WIFI_PSK in .env}"
: "${WIFI_SSID:?Need WIFI_SSID in .env}"
: "${WG_PRIVATE_KEY:?Need WG_PRIVATE_KEY in .env}"
: "${WG_PEER_PUBLIC:?Need WG_PEER_PUBLIC in .env}"
: "${WG_ENDPOINT:?Need WG_ENDPOINT in .env}"

# ---------- 1  Hash the Wi-Fi passphrase ----------
# hostapd accepts either a clear passphrase OR a 64-char PSK hash.
WIFI_PSK_HASH=$(wpa_passphrase "$WIFI_SSID" "$WIFI_PSK" | sed -n 's/^[[:space:]]*psk=//p' | head -n1)

export WIFI_PSK_HASH   # for envsubst later
echo "[DEBUG] PSK hash = $WIFI_PSK_HASH"

# ---------- 2  Render examples -> live configs ----------
envsubst < "$CFG/wg0.conf"     > /etc/wireguard/wg0.conf
envsubst < "$CFG/hostapd.conf" > /etc/hostapd/hostapd.conf
envsubst < "$CFG/dnsmasq.conf" > /etc/dnsmasq.conf
chmod 600 /etc/wireguard/wg0.conf

# ---------- 3  Kernel / iface prep ----------
sysctl -w net.ipv4.ip_forward=1 >/dev/null
modprobe wireguard 2>/dev/null || true
modprobe iptable_nat 2>/dev/null || true
AP_ADDR="${SUBNET2}1"
if ! ip addr show "$LAN_IFACE" | grep -q "$AP_ADDR/24"; then
  ip addr add "$AP_ADDR/24" dev "$LAN_IFACE"
fi

# ---------- 4  Start services ----------
# ---------- start services ----------
service hostapd restart
service dnsmasq restart
ip link show wg0 &>/dev/null && wg-quick down /etc/wireguard/wg0.conf || true
wg-quick up /etc/wireguard/wg0.conf
"$CFG/nat-rules.sh" "$LAN_IFACE" "$SUBNET"

echo "[wgwifi] SSID '$WIFI_SSID' up; clients exit via Denver"
exec tail -f /dev/null

