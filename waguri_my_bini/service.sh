#!/system/bin/sh
# Waguri My Bini - Master Stability Service v1.2-ksunext
MODDIR=${0%/*}
LOGFILE="/data/local/tmp/waguri_bini_service.log"
DISABLE_FLAG="/data/local/tmp/waguri_bini_disable"

log() {
    echo "[WAGURI-MY-BINI] $(date '+%H:%M:%S') $*" >> "$LOGFILE"
}

wait_boot() {
    log "Waiting for boot to complete..."
    while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
    log "Boot completed. Waiting 10s for system stabilization..."
    sleep 10
}

# BUG 2 FIX: Robust MediaProvider discovery & boost + FUSE Speed
fix_storage_bug() {
    log "Starting MediaProvider boost flow..."
    
    # Speed Fix: Tune FUSE read_ahead_kb to 2048
    local COUNT=0
    for bdi in /sys/class/bdi/*; do
        if [ -f "$bdi/read_ahead_kb" ]; then
            # Tune all devices, but focus on FUSE/MMC/SCSI
            echo 2048 > "$bdi/read_ahead_kb" 2>/dev/null
            COUNT=$((COUNT + 1))
        fi
    done
    log "FUSE/Storage speed tuned ($COUNT devices -> 2048KB)"

    # Persistent Protection Loop (Background)
    (
        while true; do
            # 1. Protect MediaProvider
            local MP_PID=$(pidof com.android.providers.media.module com.google.android.providers.media.module 2>/dev/null | awk '{print $1}')
            if [ -z "$MP_PID" ]; then
                MP_PID=$(ps -A -o PID,NAME 2>/dev/null | grep "providers.media" | awk '{print $1}' | head -n 1)
            fi

            if [ -n "$MP_PID" ]; then
                local current_adj=$(cat /proc/$MP_PID/oom_score_adj 2>/dev/null)
                if [ "$current_adj" != "-1000" ]; then
                    echo -1000 > /proc/$MP_PID/oom_score_adj 2>/dev/null
                fi
            fi

            # 2. Protect SystemUI and common Launchers
            for proc in com.android.systemui com.android.launcher3 com.miui.home com.google.android.apps.nexuslauncher org.lineageos.trebuchet; do
                local PID=$(pidof "$proc" 2>/dev/null | awk '{print $1}')
                if [ -n "$PID" ]; then
                    local current_adj=$(cat /proc/$PID/oom_score_adj 2>/dev/null)
                    if [ "$current_adj" != "-1000" ]; then
                        echo -1000 > /proc/$PID/oom_score_adj 2>/dev/null
                    fi
                fi
            done

            sleep 60
        done
    ) &
    log "MediaProvider persistent protection loop started."

    # Initial Trigger
    am broadcast -a android.intent.action.MEDIA_MOUNTED \
        -d file:///sdcard \
        -p com.android.providers.media.module \
        --user 0 >/dev/null 2>&1
    log "Initial MEDIA_MOUNTED broadcast sent."

    # Touch common media roots
    for dir in /sdcard/DCIM /sdcard/Pictures /sdcard/Movies /sdcard/Download; do
        [ -d "$dir" ] && touch "$dir" 2>/dev/null
    done
}

# BUG 1 FIX: Triple-prong approach to disable Rescue Party
fix_crashes() {
    log "Starting Crash Prevention flow..."
    
    # 1. via resetprop (Magisk)
    resetprop persist.device_config.global_flags.rescue_party_enabled false
    resetprop persist.sys.disable_rescue true
    
    # 2. via settings database
    settings put global device_config/global_flags/rescue_party_enabled false 2>/dev/null
    settings put global crash_loop_remedy_enabled 0 2>/dev/null
    
    # Verification
    local rp_status=$(getprop persist.device_config.global_flags.rescue_party_enabled)
    log "Rescue Party status: $rp_status (Expected: false)"
    log "Crash Prevention flow finished."
}

# --- MAIN EXECUTION FLOW ---
wait_boot

# Exit jika flag disable aktif dari post-fs-data
if [ -f "$DISABLE_FLAG" ]; then
    log "Module disabled via flag. Exiting."
    exit 0
fi

log "===== Master Service v1.2-ksunext Active ====="

# Jalankan fix secara eksplisit
fix_crashes
fix_storage_bug

# Reset boot tracker karena boot sukses
# FIX: Tandai sebagai "OK" dengan timestamp, biar post-fs-data boot berikutnya tau ini boot sukses
echo "OK:$(date +%s)" > /data/local/tmp/waguri_bini_boot_attempts
rm -f /data/local/tmp/waguri_bini_loop_*
log "Boot tracker marked OK. System stable."

# Jalankan watchdog pendukung dengan absolute path
log "Starting Watchdog..."
nohup sh "$MODDIR/watchdog.sh" >/dev/null 2>&1 &

log "Master Service tasks finished."
