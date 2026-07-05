#!/bin/sh
# =====================================================
#  Passwall2 One-Line Installer for OpenWrt
#  Supports: OpenWrt 24.10.x and older (opkg-based)
#  Repo:     https://github.com/dreamboxone/passwall2-installer
#  Usage:
#    sh -c "$(wget -qO- https://raw.githubusercontent.com/dreamboxone/passwall2-installer/main/install.sh)"
# =====================================================

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
msg()  { printf "${GREEN}[+]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[!]${NC} %s\n" "$1"; }
die()  { printf "${RED}[x]${NC} %s\n" "$1"; exit 1; }

# ---------- 0. Sanity checks ----------
[ "$(id -u)" = "0" ] || die "Please run this script as root."
[ -f /etc/openwrt_release ] || die "This system does not look like OpenWrt."

# OpenWrt versions after 24.10 (snapshots/25.x) use apk instead of opkg
if command -v apk >/dev/null 2>&1 && ! command -v opkg >/dev/null 2>&1; then
    die "This OpenWrt build uses 'apk' (newer than 24.10). This installer only supports opkg-based builds (24.10.x and older)."
fi

. /etc/openwrt_release
release="${DISTRIB_RELEASE%.*}"     # e.g. 24.10.2 -> 24.10
arch="$DISTRIB_ARCH"                # e.g. aarch64_cortex-a53

case "$DISTRIB_RELEASE" in
    *SNAPSHOT*) die "SNAPSHOT builds are not supported. Please use a stable release (24.10.x or older)." ;;
esac

msg "Detected OpenWrt $DISTRIB_RELEASE  |  Arch: $arch"

# ---------- 1. Check internet connectivity ----------
msg "Checking internet connectivity..."
if ! wget -q --spider https://master.dl.sourceforge.net 2>/dev/null && \
   ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    die "No internet connection. Please check your WAN connection first."
fi

# ---------- 2. Update package lists ----------
msg "Updating package lists (opkg update)..."
opkg update || die "opkg update failed. Check your internet/DNS and try again."

# ---------- 3. Replace dnsmasq with dnsmasq-full (safe method) ----------
# Download first, remove second -> the router is never left without DNS resolver files
if opkg list-installed | grep -q '^dnsmasq-full '; then
    msg "dnsmasq-full is already installed, skipping."
else
    msg "Replacing dnsmasq with dnsmasq-full..."
    cd /tmp
    rm -f /tmp/dnsmasq-full*.ipk
    opkg download dnsmasq-full || die "Failed to download dnsmasq-full."
    opkg remove dnsmasq 2>/dev/null || true
    opkg install /tmp/dnsmasq-full*.ipk || die "Failed to install dnsmasq-full."
    rm -f /tmp/dnsmasq-full*.ipk
fi

# ---------- 4. Firewall kernel modules ----------
if command -v fw4 >/dev/null 2>&1; then
    # OpenWrt 22.03+ : nftables / firewall4
    msg "Installing nftables kernel modules (kmod-nft-tproxy, kmod-nft-socket)..."
    opkg install kmod-nft-tproxy kmod-nft-socket || die "Failed to install nftables kernel modules."
else
    # OpenWrt 21.02 and older : iptables / firewall3
    msg "Old firewall3 detected - installing iptables modules..."
    opkg install iptables-mod-tproxy iptables-mod-iprange kmod-ipt-nat ipset || \
        warn "Some iptables modules could not be installed; Passwall2 may still work in some modes."
fi

# ---------- 5. wget-ssl + CA certificates ----------
msg "Installing wget-ssl and CA certificates..."
opkg install ca-certificates ca-bundle 2>/dev/null || opkg install ca-certificates || true
opkg install wget-ssl 2>/dev/null || opkg install wget || true

# ---------- 6. Add Passwall repository signing key ----------
msg "Adding Passwall repository signing key..."
rm -f /tmp/passwall.pub
wget -qO /tmp/passwall.pub https://master.dl.sourceforge.net/project/openwrt-passwall-build/ipk.pub || \
    die "Failed to download the repository key."
opkg-key add /tmp/passwall.pub || die "Failed to add the repository key."
rm -f /tmp/passwall.pub

# ---------- 7. Add Passwall feeds (no duplicates) ----------
FEEDS_FILE="/etc/opkg/customfeeds.conf"
touch "$FEEDS_FILE"
for feed in passwall_packages passwall2; do
    FEED_URL="https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/packages-$release/$arch/$feed"
    if grep -q "src/gz $feed " "$FEEDS_FILE" 2>/dev/null; then
        warn "Feed '$feed' already exists in customfeeds.conf, skipping."
    else
        echo "src/gz $feed $FEED_URL" >> "$FEEDS_FILE"
        msg "Feed added: $feed"
    fi
done

# ---------- 8. Update lists again (now with Passwall feeds) ----------
msg "Updating package lists with Passwall feeds..."
opkg update || die "opkg update failed after adding Passwall feeds. Your release/arch may not be available: packages-$release/$arch"

# ---------- 9. Install Passwall2 ----------
msg "Installing luci-app-passwall2 (this may take a few minutes)..."
opkg install luci-app-passwall2 || die "Failed to install luci-app-passwall2."

echo ""
msg "=============================================="
msg " Passwall2 installed successfully!"
msg " Open LuCI:  http://192.168.1.1"
msg " Menu:       Services -> Passwall2"
msg "=============================================="
