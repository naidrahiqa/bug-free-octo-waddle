#!/system/bin/sh
# My Kaoruko - post-fs-data.sh
# Bootloop Protector & Early Fix

log() {
    local msg="[KAORUKO-BOOT] $(date '+%m-%d %H:%M:%S') $*"
    echo "$msg" >> /data/local/tmp/my_kaoruko.log
}

# 1. BOOTLOOP PROTECTOR (Safety Bypass)
if [ -f "/data/local/tmp/waguri_disable" ]; then
    log "SAFETY TRIGGER: Module disabled by user. Aborting."
    exit 0
fi

# 2. Automated Bootloop Detection
TRACKER="/data/local/tmp/waguri_boot_attempts"
[ ! -f "$TRACKER" ] && echo "0" > "$TRACKER"
COUNT=$(cat "$TRACKER")

if [ "$COUNT" -gt 3 ]; then
    touch /data/local/tmp/waguri_disable
    log "BOOTLOOP DETECTED: Disabling module for safety."
    echo "0" > "$TRACKER"
    exit 0
fi

echo $((COUNT + 1)) > "$TRACKER"
log "Boot attempt: $((COUNT + 1))"

# 3. Silent Early Fixes
sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
log "Early stage complete."
