#!/system/bin/sh
# Waguri v1.3.6 - Zombie Cleaner Watchdog (Lightweight)
LOGFILE="/data/local/tmp/waguri_watchdog.log"
INTERVAL=300

log() {
    echo "[WATCHDOG] $(date '+%m-%d %H:%M:%S') $*" >> "$LOGFILE"
}

clean_zombies() {
    local count=0
    local pids=$(ps -A -o PID,STAT 2>/dev/null | grep " Z " | awk '{print $1}')
    for pid in $pids; do
        kill -9 "$pid" 2>/dev/null
        count=$((count + 1))
    done
    [ "$count" -gt 0 ] && log "Zombies cleaned: $count"
}

log "Lightweight Zombie Watchdog started (PID: $$) interval=${INTERVAL}s"
while true; do
    sleep $INTERVAL
    clean_zombies
done
