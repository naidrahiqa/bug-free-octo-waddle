#!/system/bin/sh
# Waguri v2.4.1 - Ultra Safe Watchdog (fire Edition)
# Focus: Never touch kernel PIDs, focus only on hung apps

LOGFILE="/data/local/tmp/waguri_watchdog.log"
INTERVAL=60

log() {
    local msg="[WATCHDOG] $(date '+%m-%d %H:%M:%S') $*"
    echo "$msg" >> "$LOGFILE"
}

get_process_name() {
    local pid=$1
    cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ' | awk '{print $1}'
}

is_uninterruptible() {
    local pid=$1
    local stat=$(cat /proc/$pid/stat 2>/dev/null | awk '{print $3}')
    [ "$stat" = "D" ] && return 0
    return 1
}

clean_stuck() {
    local count=0
    
    # Check system IOWait
    local cpu_stat=$(grep "cpu " /proc/stat | head -n 1)
    local iowait_val=$(echo "$cpu_stat" | awk '{print $6}')
    local total_val=$(echo "$cpu_stat" | awk '{for(i=2;i<=8;i++) sum+=$i; print sum}')
    local iowait_pct=$((iowait_val * 100 / total_val))
    
    if [ "$iowait_pct" -gt 45 ]; then
        log "SKIP: High IOWait ($iowait_pct%)"
        return
    fi

    for pid in $(ls /proc/ 2>/dev/null | grep -E '^[0-9]+$'); do
        # PROTECTION: Never touch kernel or critical system PIDs (< 2000)
        [ "$pid" -lt 2000 ] && continue

        if is_uninterruptible "$pid"; then
            local name=$(get_process_name $pid)
            [ -z "$name" ] && continue

            # Whitelist critical apps
            case "$name" in
                *launcher*|*systemui*|*magisk*|*providers.media*|*vending*|*gms*)
                    continue ;;
            esac

            local start_time=$(cat /proc/$pid/stat 2>/dev/null | awk '{print $22}')
            local uptime=$(cat /proc/uptime 2>/dev/null | awk '{print $1}' | cut -d. -f1)
            
            if [ ! -z "$start_time" ] && [ ! -z "$uptime" ]; then
                local elapsed=$((uptime - start_time))
                # 120 seconds threshold for slow Helio G88 eMMC
                if [ "$elapsed" -gt 120 ]; then
                    log "STUCK APP: $name (PID: $pid) | Time: ${elapsed}s | Killing..."
                    kill -9 "$pid" 2>/dev/null
                    count=$((count + 1))
                fi
            fi
        fi
    done
    [ "$count" -gt 0 ] && log "Watchdog: $count apps force-stopped."
}

log "Safe Watchdog started (PID: $$)"
while true; do
    sleep $INTERVAL
    clean_stuck
done
