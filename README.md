# Passwall2 Installer for OpenWrt

**🌐 Language: English | [فارسی](README.fa.md)**

---

One-line installer for [Passwall2](https://github.com/Openwrt-Passwall/openwrt-passwall2) on **OpenWrt 24.10.x and older** (opkg-based builds).

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

1. Checks that you are root, on OpenWrt, on an opkg-based release (not SNAPSHOT / apk-based)
2. Runs `opkg update`
3. Safely replaces `dnsmasq` with `dnsmasq-full` (downloads first, removes second — the router is never left without DNS)
4. Installs firewall kernel modules:
   - `kmod-nft-tproxy`, `kmod-nft-socket` on OpenWrt 22.03+ (nftables / fw4)
   - iptables tproxy modules on 21.02 and older (fw3)
5. Installs `wget-ssl` and CA certificates
6. Adds the official Passwall build repository signing key
7. Adds the `passwall_packages` and `passwall2` feeds for your exact release and CPU architecture (skips duplicates)
8. Runs `opkg update` again and installs `luci-app-passwall2`

## After installation

Open LuCI in your browser (usually `http://192.168.1.1`) and go to:

**Services → Passwall2**

## Requirements

- OpenWrt **21.02 – 24.10.x** stable release (opkg-based)
- Working internet connection on the router (WAN)
- Enough free space in overlay (~15–30 MB depending on the cores you install)

## Not supported

- SNAPSHOT builds
- OpenWrt builds newer than 24.10 that use `apk` instead of `opkg`

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
