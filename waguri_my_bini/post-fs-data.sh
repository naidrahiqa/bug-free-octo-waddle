#!/system/bin/sh
# Waguri v2.0 - post-fs-data.sh
# Bootloop Protection + Early Storage Init

log() {
    local msg="[WAGURI-V2-BOOT] $(date '+%m-%d %H:%M:%S') $*"
    echo "$msg" >> /data/local/tmp/waguri_v2.log
}

# 1. BOOTLOOP PROTECTOR
if [ -f "/data/local/tmp/waguri_v2_disable" ]; then
    log "SAFETY TRIGGER: Module disabled. Aborting."
    exit 0
fi

TRACKER="/data/local/tmp/waguri_boot_attempts"
[ ! -f "$TRACKER" ] && echo "0" > "$TRACKER"
COUNT=$(cat "$TRACKER")

if [ "$COUNT" -gt 3 ]; then
    touch /data/local/tmp/waguri_v2_disable
    log "BOOTLOOP DETECTED: Module disabled for safety."
    echo "0" > "$TRACKER"
    exit 0
fi

echo $((COUNT + 1)) > "$TRACKER"
log "Boot attempt: $((COUNT + 1))"

# 2. EARLY STORAGE INIT
# Make sure MediaProvider has high priority early
MP_PID=$(pidof com.android.providers.media.module 2>/dev/null)
if [ -z "$MP_PID" ]; then
    MP_PID=$(pidof com.android.providers.media 2>/dev/null)
fi
if [ ! -z "$MP_PID" ]; then
    echo -1000 > /proc/$MP_PID/oom_score_adj 2>/dev/null
    log "MediaProvider boosted early (PID: $MP_PID)"
fi

# 3. EARLY CACHE DROP
sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
log "Early cache drop done."
