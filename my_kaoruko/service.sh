#!/system/bin/sh
# My Kaoruko v2.0 - Infinity-X "Lite" Edition
# Target: Only fix critical bugs (storage) without touching RAM/LMKD

MODDIR=${0%/*}
LOGFILE="/data/local/tmp/my_kaoruko_lite.log"

log() {
    local msg="[KAORUKO-LITE] $(date '+%m-%d %H:%M:%S') $*"
    echo "$msg" >> "$LOGFILE"
}

wait_boot() {
    while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
}

# --- SECTION 1: STORAGE FIX ONLY ---
fix_storage_bug() {
    # Boost MediaProvider so storage doesn't randomly unmount/hide
    MP_PID=$(pidof com.android.providers.media.module)
    if [ ! -z "$MP_PID" ]; then
        echo -1000 > /proc/$MP_PID/oom_score_adj 2>/dev/null
        log "MediaProvider priority boosted (PID: $MP_PID) - Storage fix applied."
    fi

    # Trigger media scan once at boot
    am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard >/dev/null 2>&1
}

# --- SECTION 2: SYSTEM CRASH PREVENTER ---
fix_crashes() {
    # Disable rescue party to prevent bootloops from minor system UI crashes
    resetprop persist.device_config.global_flags.rescue_party_enabled false
    resetprop persist.sys.disable_rescue true
    log "Anti-crash loop applied."
}

# --- MAIN ---
wait_boot
sleep 20
log "My Kaoruko v2.0 (Lite Edition) active."

# Strip away all old aggressive background scripts
killall sleep 2>/dev/null

fix_storage_bug
fix_crashes

log "Lite execution complete. Leaving RAM management to default ROM."
