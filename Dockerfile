FROM debian:bookworm-backports

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wireguard-tools hostapd dnsmasq \
        iproute2 iptables curl procps zstd vim \
        wpasupplicant gettext-base  \
        init-system-helpers \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh        /usr/local/bin/
COPY configs/             /etc/wg-wifi/
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chmod +x /etc/wg-wifi/nat-rules.sh

VOLUME /etc/wg-wifi        # bind-mount real (edited) configs
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
