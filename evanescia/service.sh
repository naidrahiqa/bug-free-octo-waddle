#!/system/bin/sh
# Evanescia v1.0-ksunext - Memory Referee (Runtime)
# The Planarcadia referee in the arena. Monitors pressure, issues cards.

MODDIR=${0%/*}
LOGFILE="/data/local/tmp/evanescia.log"
APPLIED_FLAG="/data/local/tmp/evanescia_applied"
INTERVAL=300
RED_THRESHOLD=8
YELLOW_THRESHOLD=15

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

wait_boot() {
    while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
    sleep 30
}

referee_check() {
    local avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    local total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    local avail_pct=$((avail_kb * 100 / total_kb))
    local swap_used=$(awk '/^SwapTotal:/{t=$2} /^SwapFree:/{f=$2} END{print t-f}' /proc/meminfo)
    local swap_mb=$((swap_used / 1024))

    if [ "$avail_pct" -lt "$RED_THRESHOLD" ]; then
        log "RED CARD: avail=${avail_pct}% (${avail_kb}KB) | swap=${swap_mb}MB"
        log "  Call: page cache drop (aggressive)"
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null
    elif [ "$avail_pct" -lt "$YELLOW_THRESHOLD" ]; then
        log "YELLOW CARD: avail=${avail_pct}% (${avail_kb}KB) | swap=${swap_mb}MB"
        log "  Call: page cache drop (gentle)"
        echo 1 > /proc/sys/vm/drop_caches 2>/dev/null
    fi
}

apply_runtime_tuning() {
    local total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    local total_mb=$((total_kb / 1024))
    local swappiness=120
    local extra_free=65536
    local min_free=131072
    local vfs_pressure=80

    if [ "$total_mb" -lt 4096 ]; then
        swappiness=150
        extra_free=32768
        min_free=65536
    fi

    local current_swap=$(cat /proc/sys/vm/swappiness 2>/dev/null)
    local current_pressure=$(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null)
    local current_extra=$(cat /proc/sys/vm/extra_free_kbytes 2>/dev/null)
    local current_min=$(cat /proc/sys/vm/min_free_kbytes 2>/dev/null)
    local current_cluster=$(cat /proc/sys/vm/page-cluster 2>/dev/null)
    local current_dirty=$(cat /proc/sys/vm/dirty_ratio 2>/dev/null)
    local current_dirty_bg=$(cat /proc/sys/vm/dirty_background_ratio 2>/dev/null)

    if [ "$current_swap" != "$swappiness" ] && [ -w /proc/sys/vm/swappiness ]; then
        echo $swappiness > /proc/sys/vm/swappiness
        log "Enforced vm.swappiness = $swappiness (was $current_swap)"
    fi
    if [ "$current_pressure" != "$vfs_pressure" ] && [ -w /proc/sys/vm/vfs_cache_pressure ]; then
        echo $vfs_pressure > /proc/sys/vm/vfs_cache_pressure
        log "Enforced vm.vfs_cache_pressure = $vfs_pressure (was $current_pressure)"
    fi
    if [ "$current_extra" != "$extra_free" ] && [ -w /proc/sys/vm/extra_free_kbytes ]; then
        echo $extra_free > /proc/sys/vm/extra_free_kbytes
        log "Enforced vm.extra_free_kbytes = $extra_free (was $current_extra)"
    fi
    if [ "$current_min" != "$min_free" ] && [ -w /proc/sys/vm/min_free_kbytes ]; then
        echo $min_free > /proc/sys/vm/min_free_kbytes
        log "Enforced vm.min_free_kbytes = $min_free (was $current_min)"
    fi
    if [ "$current_cluster" != "0" ] && [ -w /proc/sys/vm/page-cluster ]; then
        echo 0 > /proc/sys/vm/page-cluster
        log "Enforced vm.page-cluster = 0 (was $current_cluster)"
    fi
    if [ "$current_dirty" != "15" ] && [ -w /proc/sys/vm/dirty_ratio ]; then
        echo 15 > /proc/sys/vm/dirty_ratio
        log "Enforced vm.dirty_ratio = 15 (was $current_dirty)"
    fi
    if [ "$current_dirty_bg" != "5" ] && [ -w /proc/sys/vm/dirty_background_ratio ]; then
        echo 5 > /proc/sys/vm/dirty_background_ratio
        log "Enforced vm.dirty_background_ratio = 5 (was $current_dirty_bg)"
    fi
}

if [ ! -f "$APPLIED_FLAG" ]; then
    log "WARN: post-fs-data not applied. Check install."
fi

wait_boot
log "==============================================="
log "  Evanescia Runtime | Referee In Arena         "
log "  Cycle: ${INTERVAL}s | Red<${RED_THRESHOLD}% | Yellow<${YELLOW_THRESHOLD}%"
log "==============================================="

# Initial enforcement after boot
apply_runtime_tuning

while true; do
    sleep $INTERVAL
    apply_runtime_tuning
    referee_check
done
