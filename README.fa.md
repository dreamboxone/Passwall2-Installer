# نصب‌کننده Passwall2 برای OpenWrt

**🌐 زبان: [English](README.md) | فارسی**

---

<div dir="rtl">

نصب تک‌خطی [Passwall2](https://github.com/Openwrt-Passwall/openwrt-passwall2) روی OpenWrt. اسکریپت **خودش تشخیص می‌ده** روترتون از کدوم پکیج‌منیجر استفاده می‌کنه و روش درست رو اجرا می‌کنه:

- **opkg** ← نسخه‌های 21.02 تا 24.10.x
- **apk** ← نسخه 25.12 به بالا و بیلدهای SNAPSHOT

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

۱. نسخه OpenWrt، معماری پردازنده و پکیج‌منیجر روتر (`opkg` یا `apk`) رو تشخیص می‌ده

۲. اتصال اینترنت رو چک می‌کنه

**روی نسخه‌های مبتنی بر opkg (نسخه 21.02 تا 24.10.x):**

- پکیج `dnsmasq` رو با روش امن با `dnsmasq-full` جایگزین می‌کنه (اول دانلود می‌کنه، بعد قدیمی رو حذف می‌کنه — یعنی روتر هیچ‌وقت بدون DNS نمی‌مونه)
- ماژول‌های کرنل فایروال رو نصب می‌کنه: روی 22.03 به بالا پکیج‌های `kmod-nft-tproxy` و `kmod-nft-socket`، روی 21.02 ماژول‌های tproxy مخصوص iptables
- پکیج `wget-ssl` و گواهی‌های CA رو نصب می‌کنه
- کلید امضای مخزن رو با `opkg-key` اضافه می‌کنه
- فیدهای `passwall_packages` و `passwall2` رو به فایل `/etc/opkg/customfeeds.conf` اضافه می‌کنه (تکراری اضافه نمی‌کنه)
- در نهایت `luci-app-passwall2` رو با `opkg` نصب می‌کنه

**روی نسخه‌های مبتنی بر apk (نسخه 25.12 به بالا و SNAPSHOT):**

- کلید امضای مخزن رو به‌صورت فایل `.pem` توی مسیر `/etc/apk/keys/` ذخیره می‌کنه
- آدرس فیدهای `packages.adb` رو به فایل `/etc/apk/repositories.d/customfeeds.list` اضافه می‌کنه — روی بیلدهای SNAPSHOT به‌صورت خودکار از فید `snapshots` و روی نسخه‌های پایدار از فید `releases` استفاده می‌کنه (تکراری اضافه نمی‌کنه)
- پکیج `dnsmasq` رو با `dnsmasq-full` جایگزین می‌کنه
- ماژول‌های `kmod-nft-tproxy` و `kmod-nft-socket` و گواهی‌های CA رو نصب می‌کنه
- در نهایت `luci-app-passwall2` رو با `apk` نصب می‌کنه

در پایان هم سرویس `rpcd` (بک‌اند LuCI) رو ری‌استارت می‌کنه تا منوی جدید نمایش داده بشه.

## بعد از نصب

توی مرورگر، پنل LuCI رو باز کنید (معمولاً `http://192.168.1.1`) و برید به:

**Services ← Passwall2**

## پیش‌نیازها

- OpenWrt نسخه **21.02 به بالا** (هم نسخه‌های مبتنی بر opkg و هم مبتنی بر apk پشتیبانی می‌شن، حتی SNAPSHOT)
- اتصال اینترنت روی روتر (WAN)
- فضای خالی کافی روی overlay (حدود ۱۵ تا ۳۰ مگابایت، بسته به هسته‌هایی که نصب می‌کنید)

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
