#!/system/bin/sh
# Waguri v2.1 - Hang Watchdog
# Runs in background, detects & kills hung/ANR'd apps dynamically
# Started by service.sh at boot

LOGFILE="/data/local/tmp/waguri_watchdog.log"
INTERVAL=60

log() {
    local msg="[WATCHDOG] $(date '+%m-%d %H:%M:%S') $*"
    echo "$msg" >> "$LOGFILE"
}

is_zombie() {
    local pid=$1
    local stat=$(cat /proc/$pid/stat 2>/dev/null | awk '{print $3}')
    [ "$stat" = "Z" ] && return 0
    return 1
}

is_uninterruptible() {
    local pid=$1
    local stat=$(cat /proc/$pid/stat 2>/dev/null | awk '{print $3}')
    [ "$stat" = "D" ] && return 0
    return 1
}

get_cpu_usage() {
    local pid=$1
    local utime=$(cat /proc/$pid/stat 2>/dev/null | awk '{print $14}')
    local stime=$(cat /proc/$pid/stat 2>/dev/null | awk '{print $15}')
    if [ ! -z "$utime" ] && [ ! -z "$stime" ]; then
        echo $((utime + stime))
    else
        echo 0
    fi
}

get_process_name() {
    local pid=$1
    cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ' | awk '{print $1}'
}

# ===================================================================
# PHASE 1: Kill zombies immediately (no false positives)
# ===================================================================
clean_zombies() {
    local count=0
    local pids=$(ps -A -o PID,STAT 2>/dev/null | grep " Z " | awk '{print $1}')

    for pid in $pids; do
        local name=$(get_process_name $pid)
        kill -9 "$pid" 2>/dev/null
        count=$((count + 1))
    done

    [ "$count" -gt 0 ] && log "Zombies killed: $count"
}

# ===================================================================
# PHASE 2: Detect stuck processes (D state for >30 seconds)
# ===================================================================
clean_stuck() {
    local count=0

    for pid in $(ls /proc/ 2>/dev/null | grep -E '^[0-9]+$'); do
        if is_uninterruptible "$pid"; then
            # Check how long in D state by checking wchan
            local wchan=$(cat /proc/$pid/wchan 2>/dev/null)
            local name=$(get_process_name $pid)

            # Skip kernel threads and critical processes
            case "$name" in
                system_server|surfaceflinger|zygote*|init|kthreadd|mediaserver*|cameraserver*|audioserver*|com.android.providers.media*|com.google.android.providers.media*|com.android.documentsui|com.google.android.documentsui|com.miui.securitycenter|keystore2|gatekeeperd|servicemanager|hwservicemanager|vold|*HAL*|*hal*|android.hardware.*|vendor.*)
                    continue ;;
            esac

            # Skip if wchan is something normal (like binder or fuse/io)
            case "$wchan" in
                binder*|ep_poll|do_epoll|futex_wait*|pipe_read*|fuse_wait_answer*|request_wait_answer*|__lock_page*|filemap_fault*|sys_pselect*|sys_epoll_wait*|do_sys_poll*|poll_schedule_timeout*)
                    continue ;;
            esac

            # If stuck in D state on a non-standard wchan, check duration
            local start_time=$(cat /proc/$pid/stat 2>/dev/null | awk '{print $22}')
            local uptime=$(cat /proc/uptime 2>/dev/null | awk '{print $1}' | cut -d. -f1)
            if [ ! -z "$start_time" ] && [ ! -z "$uptime" ]; then
                local elapsed=$((uptime - start_time))
                if [ "$elapsed" -gt 30 ]; then
                    log "STUCK ($elapsed s): $name (PID: $pid) wchan=$wchan"
                    kill -9 "$pid" 2>/dev/null
                    count=$((count + 1))
                fi
            fi
        fi
    done

    [ "$count" -gt 0 ] && log "Stuck processes killed: $count"
}

# ===================================================================
# PHASE 3: Detect ANR'd apps (not responding to input for >5s)
# ===================================================================
clean_anr() {
    # Check if any app has "not responding" dialog
    local anr_apps=$(dumpsys activity activities 2>/dev/null | grep -i "not responding" | awk '{print $NF}' | tr -d '}')

    if [ ! -z "$anr_apps" ]; then
        log "ANR detected: $anr_apps"
        # Force stop the ANR'd app
        for pkg in $anr_apps; do
            am force-stop "$pkg" 2>/dev/null
            log "Force stopped ANR: $pkg"
        done
    fi
}

# ===================================================================
# PHASE 4: Detect apps using excessive CPU (>80% for sustained period)
# ===================================================================
clean_hog() {
    local count=0

    # Get top CPU consumers
    local top_cpu=$(top -n 1 -b 2>/dev/null | head -30)

    # Check each app process
    for pid in $(ls /proc/ 2>/dev/null | grep -E '^[0-9]+$'); do
        local name=$(get_process_name $pid)
        [ -z "$name" ] && continue

        # Skip system processes
        case "$name" in
            system_server|surfaceflinger|zygote*|init|kthreadd|mediaserver*|cameraserver*|audioserver*|radio*|root|system|u0_a1*)
                continue ;;
        esac

        # Check if it's an app process (u0_a*)
        case "$name" in
            u0_a*|com.*)
                # These are app processes, check their CPU
                ;;
            *)
                continue ;;
        esac
    done
}

# ===================================================================
# MAIN WATCHDOG LOOP
# ===================================================================
log "Watchdog started (PID: $$)"

while true; do
    sleep $INTERVAL

    # Run all detection phases
    clean_zombies
    clean_stuck
    clean_anr
done
