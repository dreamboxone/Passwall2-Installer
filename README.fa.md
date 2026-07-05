# نصب‌کننده Passwall2 برای OpenWrt

**🌐 زبان: [English](README.md) | فارسی**

---

<div dir="rtl">

نصب تک‌خطی [Passwall2](https://github.com/Openwrt-Passwall/openwrt-passwall2) روی **OpenWrt نسخه 24.10.x و قدیمی‌تر** (نسخه‌هایی که از opkg استفاده می‌کنن).

## نصب سریع (فقط یک خط)

با SSH وارد روترتون بشید و این دستور رو اجرا کنید:

</div>

```sh
sh -c "$(wget -qO- https://raw.githubusercontent.com/dreamboxone/Passwall2-Installer/main/install.sh)"
```

<div dir="rtl">

اگه روی روترتون `curl` نصبه، این هم کار می‌کنه:

</div>

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/dreamboxone/Passwall2-Installer/main/install.sh)"
```

<div dir="rtl">

## این اسکریپت چیکار می‌کنه؟

۱. چک می‌کنه که با کاربر root وارد شدید، سیستم‌عامل OpenWrt هست و نسخه‌تون از opkg استفاده می‌کنه (نه SNAPSHOT و نه نسخه‌های جدید مبتنی بر apk)

۲. دستور `opkg update` رو اجرا می‌کنه

۳. پکیج `dnsmasq` رو با روش امن با `dnsmasq-full` جایگزین می‌کنه (اول دانلود می‌کنه، بعد قدیمی رو حذف می‌کنه — یعنی روتر هیچ‌وقت بدون DNS نمی‌مونه)

۴. ماژول‌های کرنل فایروال رو نصب می‌کنه:
   - روی OpenWrt نسخه 22.03 به بالا (فایروال nftables): پکیج‌های `kmod-nft-tproxy` و `kmod-nft-socket`
   - روی نسخه 21.02 و قدیمی‌تر (فایروال iptables): ماژول‌های tproxy مخصوص iptables

۵. پکیج `wget-ssl` و گواهی‌های CA رو نصب می‌کنه

۶. کلید امضای مخزن رسمی Passwall رو اضافه می‌کنه

۷. فیدهای `passwall_packages` و `passwall2` رو دقیقاً برای نسخه و معماری پردازنده روتر شما اضافه می‌کنه (اگه از قبل باشه، تکراری اضافه نمی‌کنه)

۸. دوباره `opkg update` می‌زنه و در نهایت `luci-app-passwall2` رو نصب می‌کنه

## بعد از نصب

توی مرورگر، پنل LuCI رو باز کنید (معمولاً `http://192.168.1.1`) و برید به:

**Services ← Passwall2**

## پیش‌نیازها

- OpenWrt نسخه پایدار **21.02 تا 24.10.x** (مبتنی بر opkg)
- اتصال اینترنت روی روتر (WAN)
- فضای خالی کافی روی overlay (حدود ۱۵ تا ۳۰ مگابایت، بسته به هسته‌هایی که نصب می‌کنید)

## پشتیبانی نمی‌شه

- نسخه‌های SNAPSHOT
- نسخه‌های جدیدتر از 24.10 که به‌جای `opkg` از `apk` استفاده می‌کنن

## رفع مشکلات رایج

- **بعد از اضافه شدن فیدها، `opkg update` خطا می‌ده** ← احتمالاً ترکیب نسخه/معماری روتر شما روی سرور Passwall موجود نیست. این آدرس رو چک کنید:
  `https://master.dl.sourceforge.net/project/openwrt-passwall-build/releases/`
- **فضای کافی نیست** ← با دستور `df -h /overlay` چک کنید. روترهایی که فقط ۱۶ مگابایت فلش دارن معمولاً جا برای Passwall2 به‌همراه هسته (مثلاً Xray) ندارن.
- **Passwall2 توی منوی LuCI نمایش داده نمی‌شه** ← کش LuCI رو پاک کنید: `rm -rf /tmp/luci-*` و بعد صفحه مرورگر رو رفرش کنید.

## منابع و تشکر

- پروژه Passwall2 از [Openwrt-Passwall](https://github.com/Openwrt-Passwall/openwrt-passwall2)
- پکیج‌های آماده از مخزن رسمی [openwrt-passwall-build](https://sourceforge.net/projects/openwrt-passwall-build/)

## لایسنس

MIT

</div>
