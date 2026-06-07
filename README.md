# CustomROM Fix Suite — KernelSU Next

Koleksi modul KernelSU Next (ksunext) khusus **Redmi 12 (Helio G88)** — HyperOS & custom ROM. Terbagi jadi 4 pilar yang bisa di-install terpisah atau bersamaan.

> **Target:** KernelSU Next only. Tidak kompatibel dengan Magisk murni.
> **Tested on:** Project Infinity X 3.10 (GADGETNiK), HyperOS 14 stock.

---

## Daftar Modul (latest)

### 1. Castorice Thermal v1.6-ksunext
**Fokus:** Charging & Thermal

- Smart charging dengan `charge_control_limit` (Android 12+ USB Charging spec, MTK HyperOS G88)
- Fallback ke legacy `constant_charge_current` / `input_current_limit`
- Loop pintar: re-apply cuma saat charger state berubah (bukan tulis sysfs tiap menit)
- Mendeteksi thermal throttling otomatis (kernel/PMIC yang manage, module ga override safety)
- **Catatan:** fast charge butuh charger 18W+ + kabel beneran. Charger laptop cuma 0.5A → max 2.5W.

### 2. Hyacine Fuse v1.3-ksunext
**Fokus:** Storage I/O

- Tuning `read_ahead_kb=1024` di MMC/SCSI partitions (filtered by major number, 179/8)
- Skip boot/RPMB partitions, skip loop/dm/ram devices
- Aman untuk mixed workload (gallery scroll, file copy, app launch)

### 3. Waguri My Bini v1.3.5-ksunext
**Fokus:** Stability & Storage Visibility

- MediaProvider boost + `MEDIA_MOUNTED` broadcast (Android 11+ compatible)
- Touch folder media root untuk trigger mtime refresh
- Rescue Party & crash loop remedy disabled
- SELinux rules untuk media storage access (`sepolicy.rule`)
- **Watchdog v1.3:** skip D-state (kill -9 gabisa), **protected games** (HOK/ML/PUBG/FF/miHoYo/etc. yang lo mainin — watchdog JANGAN kill), cooldown 10 menit per PID
- Bootloop protection (auto-disable setelah 3x bootloop berturut-turut)

### 4. Evanescia v1.0.1-ksunext *(baru)*
**Fokus:** Memory Referee — sysctl + zram + I/O tuning untuk ngurangin swap thrash

The Planarcadia referee: schedules the match (pre-boot), then watches in the arena (runtime).

**Pre-boot (post-fs-data):**
- `vm.swappiness` 100 → **40** (Infinity X default terlalu agresif)
- `vm.dirty_ratio` 20 → 15
- `vm.dirty_background_ratio` 10 → 5
- `vm.vfs_cache_pressure` 100 → 80
- `vm.min_free_kbytes` → 128 MB
- `vm.extra_free_kbytes` → 64 MB
- `zram` algo detection (zstd/lz4, skip kalo zram udah ada data)
- `eMMC` scheduler → `mq-deadline` (optimal buat budget SoC)

**Runtime (service.sh, 5 menit):**
- **Yellow card** <15% avail: gentle dentries/inodes reclaim
- **Red card** <8% avail: drop page cache

**Disable:** `touch /data/local/tmp/evanescia_disable`

---

## Cara Install

**Urutan yang direkomendasikan:**

1. Uninstall module Waguri/Castorice/Hyacine versi lama (via ksunext manager)
2. Reboot
3. Install `Waguri_My_Bini_v1.3-ksunext.zip` ← boot protection dulu
4. Reboot
5. Install `Castorice_Thermal_v1.6-ksunext.zip`
6. Install `Hyacine_Fuse_v1.3-ksunext.zip`
7. Install `Evanescia_v1.0.1-ksunext.zip` ← memory tuning
8. Reboot final

---

## Verifikasi

**Cek module aktif:**
```sh
su -c "ls /data/adb/modules/"
# Harus ada: castorice-thermal, hyacine-fuse, waguri-my-bini
```

**Cek log castorice (fast charge):**
```sh
cat /data/local/tmp/castorice_thermal.log
# Harus muncul: "charge_control_limit: 35 / max 36" (atau dekat max)
# BUKAN: "ERROR: Battery node not found"
```

**Cek log hyacine (I/O):**
```sh
cat /data/local/tmp/hyacine_fuse.log
# Harus muncul: "Tuned: 179:0 (major 179) -> 1024 KB" dst
# Minimal 4 device tuned
```

**Cek log waguri (stability):**
```sh
cat /data/local/tmp/waguri_bini_service.log
# Harus muncul: "MEDIA_MOUNTED broadcast sent to MediaProvider"
# "Rescue Party status: false"
```

**Monitor fast charge real-time:**
```sh
su -c "while true; do
  echo \"limit=\$(cat /sys/class/power_supply/battery/charge_control_limit)/36 current=\$(cat /sys/class/power_supply/battery/current_now) µA temp=\$(cat /sys/class/power_supply/battery/temp)\"
  sleep 3
done"
```

---

## Struktur Project

```
CustomROM-Fix/
├── castorice_thermal/       ← source v1.6
│   ├── customize.sh
│   ├── module.prop
│   └── service.sh
├── hyacine_fuse/            ← source v1.3
│   ├── customize.sh
│   ├── module.prop
│   └── service.sh
├── waguri_my_bini/          ← source v1.3.5
│   ├── customize.sh
│   ├── module.prop
│   ├── post-fs-data.sh
│   ├── sepolicy.rule
│   ├── service.sh
│   └── watchdog.sh
├── evanescia/               ← source v1.0.1 (memory referee)
│   ├── customize.sh
│   ├── module.prop
│   ├── post-fs-data.sh
│   └── service.sh
├── Castorice_Thermal_v1.6-ksunext.zip
├── Hyacine_Fuse_v1.3-ksunext.zip
├── Waguri_My_Bini_v1.3.5-ksunext.zip
├── Evanescia_v1.0.1-ksunext.zip
├── bahan rujukan/           ← reference (kernel, inferno susfs, dll)
└── repo_temp/               ← git backup, jangan dihapus
```

---

## Changelog

### v1.0.1-ksunext (evanescia) — latest
- **Initial:** Memory Referee module
- **Fix:** Zram algorithm/streams lock detection (no false success logs)
- **Fix:** I/O scheduler regex bug (was setting eMMC to `none` instead of `mq-deadline`)
- **Tuning:** vm.swappiness 100 → 40, dirty ratios, vfs_cache_pressure, min_free_kbytes
- **Runtime:** Yellow/Red card cache drop on memory pressure

### v1.3.5-ksunext (waguri) — latest
- **Fix:** Changed watchdog to monitor-only dry-run mode (commented out the `kill -9` behavior). This stops the watchdog from killing critical background system services and user apps, resolving the issue where apps refuse to open after a while and storage (internal/external) becomes unreadable.

### v1.3.4-ksunext (waguri)
- **Fix:** Watchdog process matching is now case-insensitive. Previously, mixed-case processes (like `EncoreSysMon`) did not match the lowercase patterns (like `*encoresysmon*` or `*encore*`) because `case` is case-sensitive. This caused the watchdog to kill the Encore Java daemon after 15 minutes of device uptime.

### v1.3.3-ksunext (waguri)
- **Fix:** Persistent MediaProvider protection, FUSE 2048KB speed boost, and expanded watchdog whitelist (vold, sdcard, ntfs, fuse) to prevent stuck file transfers.

### v1.3.2-ksunext (waguri) — current
- **Fix:** v1.3.1 pakai `# comment` di dalam case pattern — `#` jadi literal char, bukan shell comment. Bikin syntax error `unexpected 'newline'` di line 49, jadi watchdog ga start setelah reboot (silent fail). Sekarang pattern dipecah jadi 4 case statement terpisah (user apps / vendor / KSU / custom ROM), comment di antara-nya.
- Proteksi list sama persis kaya v1.3.1 (80+ pattern), cuma restructuring struktural

### v1.3.1-ksunext (waguri) — broken, tidak pernah start
- **Fix:** v1.3 pakai variable expansion `case $x in $LIST` — backslash di single-quote jadi literal, bukan `|`. Proteksi list hancur, watchdog bunuh SystemUI/networkstack/webview/EncoreSysMon/mi_thermald/inotifyd/watchdog-nya sendiri dalam 1 menit setelah reboot
- **Fix:** Pakai inline case pattern (metode v1.2 yang udah terbukti) + 80+ pattern: 50+ user apps, 20+ vendor (Mediatek/Xiaomi), KSU, Infinity X/LineageOS/AOSPA components
- **New:** `is_protected_game()` terpisah dari `is_protected()` biar game list ga ke-mix sama system list
- **New:** `MAX_KILL_PER_CYCLE=5` — bound damage kalau ada gap di proteksi list
- **New:** Threshold 300s → 900s (5 menit terlalu agresif untuk system service yang baru start)
- **New:** Self-PID skip — watchdog ga bunuh dirinya sendiri
- **Catatan:** File ini exist di disk tapi ga pernah start, syntax error di line 49 (see v1.3.2)

### v1.3-ksunext (waguri) — superseded (caused Encore crash)
- **Fix:** Watchdog sebelumnya spam `kill -9` ke D-state (uninterruptible I/O wait) — sinyal ga diproses sampe I/O selesai, cuma log spam doang
- **Fix:** Watchdog nge-kill game yang lo mainin (HOK, ML, dll) → PERSISTED JobScheduler restart-nya 6 jam, watchdog ga bakal menang
- **New:** `PROTECTED_GAMES` list — watchdog skip total buat game yang lo mainin (sgameGlobal, mobile.legends, miHoYo, dll)
- **New:** `PROTECTED_APPS` list — pisah dari whitelist biar maintenance gampang
- **New:** Kill cooldown 10 menit per PID, ga spam kill proses yang sama
- **New:** Cycle summary log: `killed=N skip D=N protected=N game=N recent=N`
- **New:** Track file `/data/local/tmp/waguri_kill_tracker` (PID:timestamp), auto-prune 1 jam
- **BUG:** proteksi list pakai variable expansion — backslash di single-quote jadi literal, watchdog bunuh system services (lihat v1.3.1)

### v1.6-ksunext (castorice) — latest
- **Fix:** Device HyperOS G88 ga punya `constant_charge_current` di battery node
- Pindah ke `charge_control_limit` (Android 12+ USB Charging spec)
- Fallback chain: charge_control_limit → constant_charge_current → input_current_limit

### v1.5-ksunext (castorice) — superseded
- Battery node discovery (tapi node-nya ga ada di device ini)

### v1.3-ksunext (hyacine) — latest
- **Fix:** BDI di Android formatnya `major:minor` (179:0), bukan device names
- Filter by major: 179 (MMC) & 8 (SCSI), skip loop/dm/ram
- read_ahead 2048 → 1024 (sweet spot mixed workload)

### v1.2-ksunext (waguri) — superseded
- **Fix:** `MEDIA_SCANNER_SCAN_FILE` deprecated di Android 11+
- Ganti ke `MEDIA_MOUNTED` broadcast target MediaProvider
- Tambah touch mtime di folder media root
- Watchdog threshold 120s → 300s, whitelist naik ke ~30 app
- Loop tighten dari 60s ke 30s (defensive check 5 menit)

### v1.0 — initial
- 3 module dasar: thermal, fuse, waguri

---

## Troubleshooting

**Module tidak aktif?**
- Cek di ksunext manager → module list → pastikan enabled
- `ls /data/adb/modules/<id>/disable` — kalo ada, hapus

**Fast charge masih lambat?**
- Charge pakai charger 18W+ (bukan USB laptop)
- Cek `current_now` saat charge — kalo < 0.5A, sumber daya kurang

**File masih invisible setelah install waguri?**
- Tunggu 1 menit setelah boot (MediaProvider butuh waktu)
- Test: `am start -a android.intent.action.VIEW -d "content://media/external/images/media" -p com.google.android.apps.photos`

**App masih force close?**
- Cek `/data/local/tmp/waguri_watchdog.log` — app apa yang di-kill?
- Bisa add app ke whitelist di `waguri_my_bini/watchdog.sh`

---

## Author

Castorice & Gemini CLI
