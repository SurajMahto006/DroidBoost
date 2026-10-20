# 🛠️ DroidBoost Troubleshooting Guide

Encountering an issue? Here are quick solutions for common questions and problems.

---

## 📑 Table of Contents
1. [ADB Connection Issues](#1-adb-connection-issues)
2. [Finding Your TV's IP Address](#2-finding-your-tvs-ip-address)
3. [Authorization & Permissions](#3-authorization--permissions)
4. [Recovering from a Black Screen or Home Issue](#4-recovering-from-a-black-screen-or-home-issue)
5. [Re-enabling Specific Apps](#5-re-enabling-specific-apps)
6. [Restoring the Default Google TV Launcher](#6-restoring-the-default-google-tv-launcher)
7. [Frequently Asked Questions](#7-frequently-asked-questions)

---

## 1. ADB Connection Issues

### "adb is not recognized as an internal or external command"
**Cause:** Your terminal doesn't know where `adb.exe` is located.
**Fix:**
- Option A: Run ADB by navigating directly to its folder:
  ```powershell
  cd C:\platform-tools
  .\adb.exe devices
  ```
- Option B: Add ADB to your Windows Environment Variables `PATH`.

### "Connection refused" or "cannot connect to 192.168.x.x:5555"
**Fix Checklist:**
1. **Same Wi-Fi network:** Confirm your laptop and Android TV are connected to the exact same Wi-Fi router (and not one on 2.4 GHz Guest Wi-Fi with client isolation).
2. **USB Debugging:** Verify that **Developer options → USB debugging** is enabled on the TV.
3. **Toggle Wi-Fi:** Turn TV Wi-Fi off and on again.
4. **Restart ADB Server:**
   ```powershell
   .\adb.exe kill-server
   .\adb.exe start-server
   .\adb.exe connect YOUR_TV_IP:5555
   ```

---

## 2. Finding Your TV's IP Address

Paths vary slightly depending on your TV brand:

| Brand | Settings Path |
|-------|---------------|
| **Haier** | Settings → Device Preferences → About → Status → IP address |
| **Sony BRAVIA** | Settings → Network & Internet → Network status → IP address |
| **TCL** | Settings → System → About → Status → IP address |
| **Xiaomi / Mi TV** | Settings → Network & Internet → Wi-Fi → (Connected Network) |
| **OnePlus TV** | Settings → Network & Internet → Wi-Fi → IP address |
| **Chromecast with Google TV** | Settings → System → About → Status → IP address |

---

## 3. Authorization & Permissions

### TV Status Shows `unauthorized`
When running `.\adb.exe devices`, the TV shows:
```
192.168.0.107:5555    unauthorized
```
**Fix:**
1. Look at your TV screen. A prompt will appear: **"Allow USB debugging?"**.
2. Using your TV remote, check the box **"Always allow from this computer"**.
3. Select **OK** or **Allow**.
4. Run `.\adb.exe devices` again to verify it says `device`.

---

## 4. Recovering from a Black Screen or Home Issue

If you disabled a launcher or package and the TV shows a blank screen:
1. Re-connect ADB from your computer:
   ```powershell
   .\adb.exe connect YOUR_TV_IP:5555
   ```
2. Re-enable the standard Google TV launcher:
   ```powershell
   .\adb.exe -s YOUR_TV_IP:5555 shell pm enable com.google.android.tvlauncher
   ```
3. Re-enable System UI (if touched):
   ```powershell
   .\adb.exe -s YOUR_TV_IP:5555 shell pm enable com.android.systemui
   ```
4. Reboot the TV:
   ```powershell
   .\adb.exe -s YOUR_TV_IP:5555 reboot
   ```

---

## 5. Re-enabling Specific Apps

You can restore any app at any time without factory resetting:
```powershell
.\adb.exe -s YOUR_TV_IP:5555 shell pm enable <PACKAGE_NAME>
```

**Common Examples:**
- Amazon Prime Video:
  ```powershell
  .\adb.exe -s YOUR_TV_IP:5555 shell pm enable com.amazon.amazonvideo.livingroom
  ```
- Google Play Games:
  ```powershell
  .\adb.exe -s YOUR_TV_IP:5555 shell pm enable com.google.android.play.games
  ```
- Netflix:
  ```powershell
  .\adb.exe -s YOUR_TV_IP:5555 shell pm enable com.netflix.ninja
  ```

---

## 6. Restoring the Default Google TV Launcher

If you installed TV Detox or an alternative home screen and wish to return to the original Google TV home screen:
1. Enable Google TV Launcher:
   ```powershell
   .\adb.exe -s YOUR_TV_IP:5555 shell pm enable com.google.android.tvlauncher
   ```
2. (Optional) Uninstall or disable the alternative launcher:
   ```powershell
   .\adb.exe -s YOUR_TV_IP:5555 shell pm disable-user --user 0 com.ansub.tvhome
   ```
3. Press Home on your remote or reboot:
   ```powershell
   .\adb.exe -s YOUR_TV_IP:5555 reboot
   ```

---

## 7. Frequently Asked Questions

#### Q: Will this void my TV warranty?
**A:** No. DroidBoost uses standard Android user-space commands (`pm disable-user`). It does not flash custom firmware, modify system partitions, or root the TV.

#### Q: Will this delete my Netflix/YouTube logins?
**A:** No. Disabling an app does not delete user data or credentials. If you re-enable an app, your logins remain intact.

#### Q: Can I run this on a non-smart TV with a Fire Stick?
**A:** Amazon Fire TV uses Fire OS, which restricts some package disable commands depending on firmware version. Some tweaks (animation scales) work, but certain launcher disables may be blocked by Amazon.
