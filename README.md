<div align="center">

# 🚀 DroidBoost

### Make your slow Android TV fast again — in minutes.

No root needed. No apps deleted. Everything is reversible.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20TV-blue.svg)](#supported-devices)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/SurajMahto006/DroidBoost/pulls)

</div>

---

## 🤔 Why DroidBoost?

Most Android TVs ship with **dozens of bloatware apps** running in the background — eating RAM, slowing everything down, and showing you ads. Even a brand-new TV can feel sluggish because it only has 1–2 GB of RAM shared between 50+ apps.

**DroidBoost** safely disables the junk, turns off unnecessary animations, and installs a clean home screen — all without rooting or voiding your warranty.

### Before & After (real Haier TV with 907 MB RAM)

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Available RAM | 258 MB | 276 MB | +7% |
| Swap Usage | 269 MB | 226 MB | −43 MB freed |
| Background Apps | 50+ | ~25 | −50% |
| Animations | On (laggy) | Off (instant) | ⚡ Snappy |
| Bloatware Active | 17 apps | 0 apps | 🧹 Clean |

---

## 📋 What You Need

Before starting, make sure you have:

- [ ] An **Android TV** (any brand — Haier, Sony, TCL, Xiaomi, Hisense, etc.)
- [ ] A **Windows PC/laptop** on the same Wi-Fi as your TV
- [ ] A **TV remote** (to tap a few things on-screen)
- [ ] **5–10 minutes** of your time

That's it! No programming knowledge needed.

---

## 🛠️ Step-by-Step Setup

### Step 1: Download ADB (Android Debug Bridge)

ADB is a small free tool from Google that lets your laptop talk to your TV.

1. Go to: https://developer.android.com/tools/releases/platform-tools
2. Click **"Download SDK Platform-Tools for Windows"**
3. Extract the ZIP anywhere (e.g., `C:\platform-tools`)
4. Open **PowerShell** and test it:

```powershell
cd C:\platform-tools
.\adb.exe version
```

You should see something like: `Android Debug Bridge version 1.0.41`

> **💡 Tip:** If you get an error, make sure you're in the right folder where `adb.exe` is located.

---

### Step 2: Turn on Developer Mode on Your TV

This unlocks the hidden "Developer options" menu on your TV.

1. On your TV, go to **Settings** → **Device Preferences** (or **System**) → **About**
2. Find the **Build** entry (sometimes called "Build number")
3. Press **OK on your remote 7 times** rapidly
4. You'll see a toast message: _"You are now a developer!"_

> **📺 Can't find it?** The menu path varies by brand:
> - **Sony:** Settings → About → Build
> - **Xiaomi/Mi:** Settings → About → Build number
> - **TCL:** Settings → System → About → Build
> - **Haier:** Settings → Device Preferences → About → Build

---

### Step 3: Turn on Network Debugging

1. Go back to **Settings** → **Device Preferences** (or **System**)
2. Open **Developer options** (it's now visible!)
3. Turn on **USB debugging** (and **Network debugging** if available)
4. Note your TV's **IP address** — find it in:
   - Settings → Network & Internet → (your Wi-Fi name) → IP address
   - Or Settings → About → Status → IP address

> **📝 Write down the IP!** You'll need it. It looks like: `192.168.0.107`

---

### Step 4: Connect Your Laptop to the TV

Open **PowerShell** on your laptop and run:

```powershell
cd C:\platform-tools           # or wherever you extracted ADB
.\adb.exe connect YOUR_TV_IP:5555
```

Replace `YOUR_TV_IP` with your TV's actual IP address. For example:
```powershell
.\adb.exe connect 192.168.0.107:5555
```

**📺 On your TV screen**, you'll see a popup:
> "Allow USB debugging?"

✅ **Check** "Always allow from this computer"  
✅ Press **OK / Allow**

Then verify the connection:
```powershell
.\adb.exe devices
```

You should see:
```
List of devices attached
192.168.0.107:5555    device
```

> **⚠️ If it says `unauthorized`:** Go back to the TV and accept the debugging prompt, then run `.\adb.exe devices` again.

---

### Step 5: Run DroidBoost!

#### Option A: Quick Auto-Clean (Recommended for beginners)

Download and run the cleanup script:

```powershell
# Clone DroidBoost
git clone https://github.com/SurajMahto006/DroidBoost.git
cd DroidBoost\scripts

# Run the cleanup (replace with YOUR TV's IP)
powershell -ExecutionPolicy Bypass -File .\cleanup.ps1 -TvIp "192.168.0.107"
```

The script will:
1. ✅ Show you every app on your TV
2. ✅ Ask before disabling anything
3. ✅ Disable only safe bloatware
4. ✅ Turn off laggy animations
5. ✅ Set a 5-minute sleep timer
6. ✅ Reboot your TV

#### Option B: Manual Control (Pick what to disable)

If you want to choose exactly which apps to disable:

```powershell
# See all apps on your TV
.\adb.exe -s YOUR_TV_IP:5555 shell pm list packages

# Disable a specific app (example: Amazon Prime Video)
.\adb.exe -s YOUR_TV_IP:5555 shell pm disable-user --user 0 com.amazon.amazonvideo.livingroom

# Re-enable it if needed
.\adb.exe -s YOUR_TV_IP:5555 shell pm enable com.amazon.amazonvideo.livingroom
```

---

## 🧹 What Gets Disabled?

DroidBoost identifies three categories of apps:

### ✅ Safe to Disable (Bloatware)

These waste RAM and are not needed for your TV to work:

| App | Package Name | Why Disable? |
|-----|-------------|-------------|
| Amazon Prime Video | `com.amazon.amazonvideo.livingroom` | Pre-installed streaming bloat |
| Google TV Recommendations | `com.google.android.tvrecommendations` | Background RAM hog, shows ads |
| Google Backdrop (Screensaver) | `com.google.android.backdrop` | Uses ~77 MB RAM |
| Google TV Setup | `com.google.android.tungsten.setupwraith` | Setup wizard, uses ~57 MB RAM |
| Google Feedback | `com.google.android.feedback` | Error reporting, not needed |
| Calendar Sync | `com.google.android.syncadapters.calendar` | No calendar needed on TV |
| Calendar Provider | `com.android.providers.calendar` | Calendar backend |
| Contacts Provider | `com.android.providers.contacts` | No contacts on TV |
| Print Spooler | `com.android.printspooler` | Printing from a TV? No. |
| Desk Clock | `com.android.deskclock` | Alarms on a TV? No. |
| Sound Picker | `com.android.soundpicker` | Ringtone picker |
| Retail Demo | `fusion.android.tv.demo` | Store display mode |
| TalkBack | `com.google.android.marvin.talkback` | Screen reader (disable if not needed) |
| YouTube Music | `com.google.android.youtube.tvmusic` | Rarely used on TVs |
| Google Play Games | `com.google.android.play.games` | Gaming service, wastes RAM |
| Netflix | `com.netflix.ninja` | Disable if you don't use it |

### 🤔 Ask First (Depends on You)

| App | Package Name | What It Does |
|-----|-------------|-------------|
| Haier EvoSmart | `com.haier.apps.evoSmart` | Smart home features |
| Haier uSmart | `com.haierubic.usmartdevice` | IoT device control |
| Haier Apps Hub | `com.haier.apps` | Haier's app store |
| Shahid (MBC) | `com.haier.apps.shahid` | Middle Eastern streaming |
| Anoki ACR | `tv.anoki.acr.controller` | **Ad tracking** — disable this! |
| Screen Mirroring | Various | Disable if not using |

### 🔒 Never Disable (TV Will Break!)

| App | Package Name | Why It's Protected |
|-----|-------------|-------------------|
| Android System | `android` | Core OS |
| System UI | `com.android.systemui` | Screen, notifications |
| Settings | `com.android.tv.settings` | TV Settings |
| Google Play Services | `com.google.android.gms` | Core Google services |
| Google Play Store | `com.android.vending` | App installs |
| Keyboard (Gboard) | `com.google.android.inputmethod.latin` | On-screen keyboard |
| Bluetooth | `com.android.bluetooth` | Remote control |
| Wi-Fi | `com.android.wifi.resources` | Internet |
| TV Input (HDMI) | `com.mediatek.tvinput` | HDMI switching |
| TV Service | `com.mediatek.tv.service` | Core TV framework |
| Live TV / Tuner | `com.mediatek.wwtv.tvcenter` | TV channels |
| WebView | `com.google.android.webview` | Web rendering |

---

## ⚡ Performance Tweaks

DroidBoost also applies these system tweaks:

### Disable Animations (Makes UI feel instant)
```powershell
.\adb.exe -s YOUR_TV_IP:5555 shell settings put global window_animation_scale 0
.\adb.exe -s YOUR_TV_IP:5555 shell settings put global transition_animation_scale 0
.\adb.exe -s YOUR_TV_IP:5555 shell settings put global animator_duration_scale 0
```

### Disable Screensaver (Saves RAM)
```powershell
.\adb.exe -s YOUR_TV_IP:5555 shell settings put secure screensaver_enabled 0
```

### Set Sleep Timeout to 5 Minutes
```powershell
.\adb.exe -s YOUR_TV_IP:5555 shell settings put system screen_off_timeout 300000
```

---

## ↩️ How to Undo Everything

**Nothing is deleted.** Every disabled app can be re-enabled instantly.

### Re-enable a single app:
```powershell
.\adb.exe -s YOUR_TV_IP:5555 shell pm enable com.amazon.amazonvideo.livingroom
```

### Re-enable ALL disabled apps:
```powershell
# Run the undo script
powershell -ExecutionPolicy Bypass -File .\scripts\undo.ps1 -TvIp "YOUR_TV_IP"
```

### Restore animations:
```powershell
.\adb.exe -s YOUR_TV_IP:5555 shell settings put global window_animation_scale 1
.\adb.exe -s YOUR_TV_IP:5555 shell settings put global transition_animation_scale 1
.\adb.exe -s YOUR_TV_IP:5555 shell settings put global animator_duration_scale 1
```

---

## 📱 Supported Devices

DroidBoost works on any TV running **Android TV** or **Google TV**:

| Brand | Tested? | Notes |
|-------|---------|-------|
| **Haier** | ✅ Yes | Fully tested on Android 11 |
| **Sony (BRAVIA)** | Should work | Android TV / Google TV |
| **TCL** | Should work | Most models run Android TV |
| **Xiaomi (Mi TV)** | Should work | Runs Android TV |
| **Hisense** | Should work | Android TV models |
| **Philips** | Should work | Android TV models |
| **NVIDIA Shield** | Should work | Android TV |
| **Chromecast w/ Google TV** | Should work | Google TV |

> **⚠️ Not supported:** Roku TVs, Samsung (Tizen), LG (webOS), or Amazon Fire TV (partially).

---

## 📂 Project Structure

```
DroidBoost/
├── README.md                  # This file
├── LICENSE                    # MIT License
├── scripts/
│   ├── cleanup.ps1            # Main cleanup script (Windows)
│   ├── cleanup.sh             # Main cleanup script (Mac/Linux)
│   ├── undo.ps1               # Undo all changes (Windows)
│   └── undo.sh                # Undo all changes (Mac/Linux)
├── configs/
│   └── bloatware-list.json    # Known safe-to-disable apps
└── docs/
    └── TROUBLESHOOTING.md     # Common issues & fixes
```

---

## ❓ Troubleshooting

<details>
<summary><b>"adb is not recognized"</b></summary>

You need to `cd` into the folder where ADB is extracted, or add it to your system PATH:
```powershell
# Either cd to the folder:
cd C:\platform-tools

# Or use the full path:
C:\platform-tools\adb.exe devices
```
</details>

<details>
<summary><b>"failed to authenticate" or "unauthorized"</b></summary>

Your TV is showing a permission popup. Look at your TV screen and:
1. Check "Always allow from this computer"
2. Press OK / Allow
3. Run `.\adb.exe devices` again
</details>

<details>
<summary><b>"Can't reach the TV" or "connection refused"</b></summary>

1. Make sure your TV and laptop are on the **same Wi-Fi network**
2. Make sure **USB debugging** is turned on in Developer Options
3. Try turning Network debugging off and on again
4. Restart the TV and try again
</details>

<details>
<summary><b>TV boots to a black screen after disabling apps</b></summary>

Don't panic! Connect via ADB and re-enable everything:
```powershell
.\adb.exe connect YOUR_TV_IP:5555
.\adb.exe -s YOUR_TV_IP:5555 shell pm enable com.google.android.tvlauncher
.\adb.exe -s YOUR_TV_IP:5555 shell pm enable com.android.systemui
.\adb.exe -s YOUR_TV_IP:5555 reboot
```
</details>

<details>
<summary><b>"I disabled something and now X doesn't work"</b></summary>

Just re-enable it:
```powershell
.\adb.exe -s YOUR_TV_IP:5555 shell pm enable PACKAGE_NAME
```
Replace `PACKAGE_NAME` with the app's package name from the tables above.
</details>

---

## 🤝 Contributing

Found a new bloatware app? Tested on a new TV brand? PRs are welcome!

1. Fork the repo
2. Add your changes
3. Submit a Pull Request

If you tested DroidBoost on a TV brand not listed above, please open an issue with:
- TV brand and model
- Android version
- What you disabled and what happened

---

## 📜 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file.

---

## ⚠️ Disclaimer

This tool disables apps — it never deletes them. Everything can be undone. However, **use at your own risk.** The authors are not responsible for any issues with your TV. Always make sure you understand what you're disabling before proceeding.

---

<div align="center">

**Made with ❤️ for everyone tired of slow, bloated Android TVs.**

⭐ **Star this repo** if DroidBoost helped your TV!

</div>
