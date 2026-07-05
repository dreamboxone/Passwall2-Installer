# Passwall2 Installer for OpenWrt

**🌐 Language: English | [فارسی](README.fa.md)**

---

One-line installer for [Passwall2](https://github.com/Openwrt-Passwall/openwrt-passwall2) on OpenWrt. **Auto-detects your package manager** and uses the right method:

- **opkg** → OpenWrt 21.02 – 24.10.x
- **apk** → OpenWrt 25.12+ and SNAPSHOT builds

## Quick Install (one line)

SSH into your router and run:

```sh
sh -c "$(wget -qO- https://raw.githubusercontent.com/dreamboxone/Passwall2-Installer/main/install.sh)"
```

If your build has `curl` instead:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/dreamboxone/Passwall2-Installer/main/install.sh)"
```

## What the script does

1. Detects your OpenWrt version, CPU architecture, and package manager (`opkg` or `apk`)
2. Checks internet connectivity

**On opkg-based builds (21.02 – 24.10.x):**
- Safely replaces `dnsmasq` with `dnsmasq-full` (downloads first, removes second — the router is never left without DNS)
- Installs firewall kernel modules: `kmod-nft-tproxy` + `kmod-nft-socket` on 22.03+ (fw4), or iptables tproxy modules on 21.02 (fw3)
- Installs `wget-ssl` and CA certificates
- Adds the repository signing key with `opkg-key`
- Adds the `passwall_packages` and `passwall2` feeds to `/etc/opkg/customfeeds.conf` (skips duplicates)
- Installs `luci-app-passwall2` with `opkg`

**On apk-based builds (25.12+ / SNAPSHOT):**
- Adds the repository signing key as a `.pem` file in `/etc/apk/keys/`
- Adds the `packages.adb` feed URLs to `/etc/apk/repositories.d/customfeeds.list` — automatically using the `snapshots` feed on SNAPSHOT builds and the `releases` feed on stable builds (skips duplicates)
- Replaces `dnsmasq` with `dnsmasq-full`
- Installs `kmod-nft-tproxy` + `kmod-nft-socket` and CA certificates
- Installs `luci-app-passwall2` with `apk`

Finally, it restarts the LuCI backend (`rpcd`) so the new menu shows up.

## After installation

Open LuCI in your browser (usually `http://192.168.1.1`) and go to:

**Services → Passwall2**

## Requirements

- OpenWrt **21.02 or newer** (both opkg-based and apk-based builds are supported, including SNAPSHOT)
- Working internet connection on the router (WAN)
- Enough free space in overlay (~15–30 MB depending on the cores you install)

## Troubleshooting

- **`opkg update` fails after adding feeds** → your release/arch combo may not exist on the Passwall build server. Check:
  `https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/`
- **Out of space** → check with `df -h /overlay`. Passwall2 + a core (e.g. Xray) needs free space; small 16 MB flash routers usually can't fit it.
- **LuCI menu doesn't show Passwall2** → clear the LuCI cache: `rm -rf /tmp/luci-*` then refresh the browser.

## Credits

- Passwall2 by [Openwrt-Passwall](https://github.com/Openwrt-Passwall/openwrt-passwall2)
- Prebuilt packages from the official [openwrt-passwall-build](https://sourceforge.net/projects/openwrt-passwall-build/) repository

## License

MIT
