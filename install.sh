#!/bin/sh
# =====================================================
#  Passwall2 One-Line Installer for OpenWrt
#  Auto-detects the package manager:
#    - opkg : OpenWrt 21.02 - 24.10.x
#    - apk  : OpenWrt 25.12+ and SNAPSHOT builds
#  Repo:  https://github.com/dreamboxone/Passwall2-Installer
#  Usage:
#    sh -c "$(wget -qO- https://raw.githubusercontent.com/dreamboxone/Passwall2-Installer/main/install.sh)"
# =====================================================

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
msg()  { printf "${GREEN}[+]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[!]${NC} %s\n" "$1"; }
die()  { printf "${RED}[x]${NC} %s\n" "$1"; exit 1; }

SF_BASE="https://master.dl.sourceforge.net/project/openwrt-passwall-build"

# Primary source for the signing key: this installer's own GitHub repo
# (a verbatim copy of the official key from openwrt-passwall-build).
# GitHub is reachable whenever the installer itself could be downloaded.
GH_KEY_BASE="https://raw.githubusercontent.com/dreamboxone/Passwall2-Installer/main"

# Fallback sources for the key - used ONLY if the GitHub download fails.
SF_MIRRORS="
https://master.dl.sourceforge.net/project/openwrt-passwall-build
https://downloads.sourceforge.net/project/openwrt-passwall-build
https://netix.dl.sourceforge.net/project/openwrt-passwall-build
https://phoenixnap.dl.sourceforge.net/project/openwrt-passwall-build
"

# dl <output-file> <url> : download with a 15s timeout, 2 tries, never hangs
dl() {
    wget -T 15 -t 2 -qO "$1" "$2" 2>/dev/null
}

# valid_key <file> : non-empty and not an HTML error page
valid_key() {
    [ -s "$1" ] && ! head -c 200 "$1" | grep -qi "<html\|<!doctype"
}

# fetch_key <keyname> <output-file> :
# 1) GitHub (this repo) - if it works, we are done, nothing else is tried.
# 2) Only if GitHub fails: SourceForge mirrors, then the SF redirect URL.
fetch_key() {
    keyname="$1"; out="$2"

    msg "Downloading key from GitHub: $GH_KEY_BASE/$keyname"
    rm -f "$out"
    if dl "$out" "$GH_KEY_BASE/$keyname" && valid_key "$out"; then
        msg "Key downloaded from GitHub."
        return 0
    fi

    warn "GitHub download failed - falling back to SourceForge mirrors..."
    for base in $SF_MIRRORS; do
        msg "Trying mirror: $base"
        rm -f "$out"
        if dl "$out" "$base/$keyname" && valid_key "$out"; then
            msg "Key downloaded."
            return 0
        fi
        warn "Mirror failed or timed out, trying the next one..."
    done

    msg "Trying SourceForge auto-redirect URL..."
    rm -f "$out"
    if dl "$out" "https://sourceforge.net/projects/openwrt-passwall-build/files/$keyname/download" && valid_key "$out"; then
        return 0
    fi
    rm -f "$out"
    return 1
}

# ---------- 0. Sanity checks ----------
[ "$(id -u)" = "0" ] || die "Please run this script as root."
[ -f /etc/openwrt_release ] || die "This system does not look like OpenWrt."

. /etc/openwrt_release
release="${DISTRIB_RELEASE%.*}"     # e.g. 24.10.2 -> 24.10
arch="$DISTRIB_ARCH"                # e.g. aarch64_cortex-a53

IS_SNAPSHOT=0
case "$DISTRIB_RELEASE" in
    *SNAPSHOT*) IS_SNAPSHOT=1 ;;
esac

# ---------- 1. Detect package manager ----------
if command -v apk >/dev/null 2>&1; then
    PKG="apk"       # OpenWrt 25.12+ / SNAPSHOT
elif command -v opkg >/dev/null 2>&1; then
    PKG="opkg"      # OpenWrt 24.10.x and older
else
    die "Neither opkg nor apk found. Unsupported system."
fi

msg "Detected OpenWrt $DISTRIB_RELEASE  |  Arch: $arch  |  Package manager: $PKG"

# ---------- 2. Check internet connectivity ----------
msg "Checking internet connectivity..."
if ! wget -T 8 -t 1 -q --spider https://sourceforge.net 2>/dev/null && \
   ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    die "No internet connection. Please check your WAN connection first."
fi

# =====================================================
#  OPKG PATH  (OpenWrt 21.02 - 24.10.x)
# =====================================================
install_via_opkg() {
    msg "Updating package lists (opkg update)..."
    opkg update || die "opkg update failed. Check your internet/DNS and try again."

    # --- dnsmasq-full swap (safe method: download first, remove second) ---
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

    # --- firewall kernel modules ---
    if command -v fw4 >/dev/null 2>&1; then
        msg "Installing nftables kernel modules (kmod-nft-tproxy, kmod-nft-socket)..."
        opkg install kmod-nft-tproxy kmod-nft-socket || die "Failed to install nftables kernel modules."
    else
        msg "Old firewall3 detected - installing iptables modules..."
        opkg install iptables-mod-tproxy iptables-mod-iprange kmod-ipt-nat ipset || \
            warn "Some iptables modules could not be installed; Passwall2 may still work in some modes."
    fi

    # --- wget-ssl + CA certificates ---
    msg "Installing wget-ssl and CA certificates..."
    opkg install ca-certificates ca-bundle 2>/dev/null || opkg install ca-certificates || true
    opkg install wget-ssl 2>/dev/null || opkg install wget || true

    # --- repository signing key (ipk.pub for opkg-based builds) ---
    msg "Adding Passwall repository signing key (opkg)..."
    rm -f /tmp/passwall.pub
    fetch_key "ipk.pub" /tmp/passwall.pub || \
        die "Failed to download the repository key (ipk.pub) from GitHub and all fallback mirrors. Check your internet connection."
    opkg-key add /tmp/passwall.pub || die "Failed to add the repository key."
    rm -f /tmp/passwall.pub

    # --- feeds (no duplicates) ---
    FEEDS_FILE="/etc/opkg/customfeeds.conf"
    touch "$FEEDS_FILE"
    for feed in passwall_packages passwall2; do
        FEED_URL="$SF_BASE/releases/packages-$release/$arch/$feed"
        if grep -q "src/gz $feed " "$FEEDS_FILE" 2>/dev/null; then
            warn "Feed '$feed' already exists in customfeeds.conf, skipping."
        else
            echo "src/gz $feed $FEED_URL" >> "$FEEDS_FILE"
            msg "Feed added: $feed"
        fi
    done

    msg "Updating package lists with Passwall feeds..."
    opkg update || die "opkg update failed after adding Passwall feeds. Your release/arch may not be available: packages-$release/$arch"

    msg "Installing luci-app-passwall2 (this may take a few minutes)..."
    opkg install luci-app-passwall2 || die "Failed to install luci-app-passwall2."
}

# =====================================================
#  APK PATH  (OpenWrt 25.12+ and SNAPSHOT builds)
# =====================================================
install_via_apk() {
    if [ "$IS_SNAPSHOT" = "1" ]; then
        warn "SNAPSHOT build detected - using the snapshots feed."
    fi

    # --- repository signing key (apk.pub) -> /etc/apk/keys/*.pem ---
    msg "Adding Passwall repository signing key (apk)..."
    mkdir -p /etc/apk/keys
    fetch_key "apk.pub" /etc/apk/keys/openwrt-passwall-build.pem || \
        die "Failed to download the repository key (apk.pub) from GitHub and all fallback mirrors. Check your internet connection."

    # --- feeds -> /etc/apk/repositories.d/customfeeds.list (no duplicates) ---
    FEEDS_FILE="/etc/apk/repositories.d/customfeeds.list"
    mkdir -p /etc/apk/repositories.d
    touch "$FEEDS_FILE"
    for feed in passwall_packages passwall2; do
        if [ "$IS_SNAPSHOT" = "1" ]; then
            FEED_URL="$SF_BASE/snapshots/packages/$arch/$feed/packages.adb"
        else
            FEED_URL="$SF_BASE/releases/packages-$release/$arch/$feed/packages.adb"
        fi
        if grep -q "/$feed/packages.adb" "$FEEDS_FILE" 2>/dev/null; then
            warn "Feed '$feed' already exists in customfeeds.list, skipping."
        else
            echo "$FEED_URL" >> "$FEEDS_FILE"
            msg "Feed added: $feed"
        fi
    done

    # --- update package index ---
    msg "Updating package lists (apk update)..."
    apk update || die "apk update failed. Your release/arch may not be available on the Passwall build server."

    # --- dnsmasq-full swap ---
    if apk list --installed 2>/dev/null | grep -q '^dnsmasq-full'; then
        msg "dnsmasq-full is already installed, skipping."
    else
        msg "Replacing dnsmasq with dnsmasq-full..."
        if ! apk add dnsmasq-full 2>/dev/null; then
            apk del dnsmasq 2>/dev/null || true
            apk add dnsmasq-full || die "Failed to install dnsmasq-full."
        fi
    fi

    # --- firewall kernel modules (apk builds are always nftables/fw4) ---
    msg "Installing nftables kernel modules (kmod-nft-tproxy, kmod-nft-socket)..."
    apk add kmod-nft-tproxy kmod-nft-socket || die "Failed to install nftables kernel modules."

    # --- CA certificates ---
    msg "Installing CA certificates..."
    apk add ca-certificates ca-bundle 2>/dev/null || apk add ca-certificates || true

    # --- install Passwall2 ---
    msg "Installing luci-app-passwall2 (this may take a few minutes)..."
    apk add luci-app-passwall2 || die "Failed to install luci-app-passwall2."
}

# ---------- 3. Run the right installer ----------
if [ "$PKG" = "opkg" ]; then
    install_via_opkg
else
    install_via_apk
fi

# ---------- 4. Restart LuCI backend ----------
msg "Restarting LuCI backend (rpcd)..."
/etc/init.d/rpcd restart 2>/dev/null || true

echo ""
msg "=============================================="
msg " Passwall2 installed successfully!"
msg " Open LuCI:  http://192.168.1.1"
msg " Menu:       Services -> Passwall2"
msg "=============================================="
