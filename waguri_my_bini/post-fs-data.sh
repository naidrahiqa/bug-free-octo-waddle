#!/system/bin/sh
# Waguri My Bini - Stable Boot Protection v1.2-ksunext
MODDIR=${0%/*}

# MASALAH 4 FIX: Proteksi Akses /data
TRACKER="/data/local/tmp/waguri_bini_boot_attempts"
DISABLE_FLAG="/data/local/tmp/waguri_bini_disable"
LOGFILE="/data/local/tmp/waguri_bini_boot.log"

# Tunggu folder /data siap pakai (max 10 detik)
timeout=0
while [ ! -d "/data/local/tmp" ] || [ ! -w "/data/local/tmp" ]; do
    sleep 1
    timeout=$((timeout + 1))
    if [ $timeout -gt 10 ]; then
        # Jika /data tidak siap setelah 10s, kemungkinan besar bootloop/ecryptfs error
        # Disable modul demi keselamatan
        touch "$MODDIR/disable"
        exit 0
    fi
done

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

# Logika Tracker Bootloop
# FIX: Tracker lama increment tiap boot, jadi reboot 4x normal = module disable sendiri.
# Sekarang: pakai timestamp. Hanya increment kalau post-fs-data jalan < 60 detik setelah
# boot sebelumnya (tanda bootloop/crash). service.sh reset marker pakai "OK:<ts>".
TRACKER_VALUE=$(cat "$TRACKER" 2>/dev/null)
NOW=$(date +%s)

if [ -z "$TRACKER_VALUE" ]; then
    echo "$NOW" > "$TRACKER"
    log "First boot recorded at $NOW"
elif echo "$TRACKER_VALUE" | grep -qE '^OK:[0-9]+$'; then
    # service.sh menandai boot terakhir sebagai sukses → reset ke fresh timestamp
    echo "$NOW" > "$TRACKER"
    log "Previous boot was successful. Reset tracker at $NOW"
elif echo "$TRACKER_VALUE" | grep -qE '^[0-9]+$'; then
    DELTA=$((NOW - TRACKER_VALUE))
    if [ "$DELTA" -lt 60 ]; then
        # Post-fs-data jalan lagi < 60 detik sejak attempt terakhir → bootloop
        BOOT_ATTEMPTS=$(ls -1 /data/local/tmp/waguri_bini_loop_* 2>/dev/null | wc -l)
        BOOT_ATTEMPTS=$((BOOT_ATTEMPTS + 1))
        echo "$BOOT_ATTEMPTS" > "/data/local/tmp/waguri_bini_loop_$NOW"
        log "Bootloop detected (delta=${DELTA}s). Attempt #$BOOT_ATTEMPTS"
        if [ "$BOOT_ATTEMPTS" -gt 3 ]; then
            log "CRITICAL: Bootloop > 3x. Disabling module."
            touch "$MODDIR/disable"
            exit 0
        fi
    else
        # Boot normal (>60s sejak attempt terakhir) → reset
        echo "$NOW" > "$TRACKER"
        log "Normal boot (delta=${DELTA}s). Reset tracker."
    fi
fi

# Basic ROM Bug Fixes dipindah ke service.sh — di post-fs-data, property subsystem
# belum ready di banyak ROM (khusunya G88/HyperOS), resetprop bisa silent fail.
