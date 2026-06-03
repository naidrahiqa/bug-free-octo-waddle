#!/system/bin/sh
# Waguri My Bini v1.0 - Stability & ROM Bug Fixes
# Focus: PIN bugs, app crashes, rescue party, stability tweaks

MODDIR=${0%/*}
LOGFILE="/data/local/tmp/waguri_my_bini.log"

log() {
    local msg="[WAGURI-MY-BINI] $(date '+%m-%d %H:%M:%S') $*"
    echo "$msg" >> "$LOGFILE"
}

wait_boot() {
    while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
}

detect_info() {
    DEVICE=$(getprop ro.product.model 2>/dev/null)
    local mem_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    TOTAL_RAM_MB=$((mem_kb / 1024))
    
    ENCORE_ACTIVE=0
    [ -d "/data/adb/modules/encore" ] && ENCORE_ACTIVE=1
}

fix_memory() {
    log "Applying memory tweaks..."
    sync; echo 3 > /proc/sys/vm/drop_caches
    local min_free=$((TOTAL_RAM_MB * 1000 / 200))
    [ "$min_free" -lt 24000 ] && min_free=24000
    [ "$min_free" -gt 96000 ] && min_free=96000
    echo "$min_free" > /proc/sys/vm/min_free_kbytes
    echo 80 > /proc/sys/vm/swappiness
    echo 50 > /proc/sys/vm/vfs_cache_pressure
}

fix_crashes() {
    log "Disabling Rescue Party & Crash Loop Remedy..."
    resetprop persist.device_config.global_flags.rescue_party_enabled false
    resetprop persist.sys.disable_rescue true
    settings put global crash_loop_remedy_enabled 0 2>/dev/null
}

wait_boot

sleep 25
log "===== Waguri My Bini v1.0 active ====="
detect_info
fix_crashes

if [ "$ENCORE_ACTIVE" -eq 0 ]; then
    fix_memory
else
    log "Encore detected: Skipping memory tweaks."
fi

# Start watchdog in background
nohup sh "$MODDIR/watchdog.sh" >/dev/null 2>&1 &
