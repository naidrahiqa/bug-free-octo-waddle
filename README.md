# Waguri - CustomROM Fix Suite

Koleksi modul khusus untuk Project Infinity X (POCO F5) & Inferno Kernel. Terbagi menjadi 3 pilar utama untuk menghindari konflik.

## Daftar Modul

### 1. Castorice Thermal v1.0
**Fokus:** Performa & Charging
- Menghilangkan *Thermal Throttling* (Neutralize MTK Cooling Devices).
- Memaksa *Fast Charging* (Force `charge_control_limit`).
- Gaming Boost: CPU Performance & GPU Scaling.
- Otomatis ganti profile: Screen ON (Extreme) / Screen OFF (Balanced).

### 2. Hyacine Fuse v1.0
**Fokus:** Storage & File Visibility
- Mematikan *FUSE Passthrough* (Root cause aplikasi tidak bisa buka PDF/Docx).
- Meningkatkan *I/O Read-ahead* (2048KB) untuk transfer file super cepat.
- Memperbaiki masalah storage tidak kedeteksi di Gallery/File Manager.

### 3. Waguri My Bini v1.0
**Fokus:** ROM Bug Fix & Stability
- Whitelist Watchdog: Mencegah *PIN Lock bug* (Keystore/Gatekeeper ga bakal dibunuh).
- Fix IG Logout: Logika mounting storage yang lebih aman & stabil.
- Anti-Crash: Disable Rescue Party & Crash Loop Remedy.
- Memory Tuning: Adaptive min_free_kbytes (Otomatis ngalah kalo ada modul Encore).

---

## Cara Instalasi
1. Hapus semua modul Waguri versi lama.
2. Install ketiga zip baru: `Castorice_Thermal_v1.0.zip`, `Hyacine_Fuse_v1.0.zip`, `Waguri_My_Bini_v1.0.zip`.
3. Reboot.

## Author
Gemini CLI & Castorice
