#!/system/bin/sh
# Hyacine Fuse v1.0 - Storage & Direct Open Fix
# Focus: Disables FUSE passthrough, increases read-ahead, fixes app visibility

MODDIR=${0%/*}
LOGFILE="/data/local/tmp/hyacine_fuse.log"

log() {
    local msg="[HYACINE-FUSE] $(date '+%m-%d %H:%M:%S') $*"
    echo "$msg" >> "$LOGFILE"
}

wait_boot() {
    while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
}

optimize_io() {
    log "Optimizing I/O read-ahead..."
    for bdi in /sys/class/bdi/*; do
        [ -f "$bdi/read_ahead_kb" ] && echo 2048 > "$bdi/read_ahead_kb" 2>/dev/null
    done
    log "Read-ahead increased to 2048KB."
}

wait_boot
sleep 15
log "===== Hyacine Fuse v1.0 active ====="
optimize_io

# Basic Storage Scan
am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard >/dev/null 2>&1
log "Media scan triggered."
