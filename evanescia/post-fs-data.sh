#!/system/bin/sh
# Evanescia v1.0-ksunext - Memory Referee
# The Planarcadia referee: sets the rules before the match starts.
# Applies vm tuning, zram config, I/O scheduler — all in pre-boot phase.

MODDIR=${0%/*}
LOGFILE="/data/local/tmp/evanescia.log"
DISABLE_FLAG="/data/local/tmp/evanescia_disable"
APPLIED_FLAG="/data/local/tmp/evanescia_applied"

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

# --- DEFAULT TUNING (8 GB devices) ---
SWAPPINESS=120
DIRTY_RATIO=15
DIRTY_BG_RATIO=5
VFS_CACHE_PRESSURE=80
MIN_FREE_KB=131072
EXTRA_FREE_KB=65536

# --- DISABLE CHECK ---
if [ -f "$DISABLE_FLAG" ]; then
    log "Module disabled via flag. Evanescia stands down."
    exit 0
fi

log "==============================================="
log "  Evanescia v1.0.1-ksunext | Referee Active   "
log "==============================================="

# Detect total RAM
total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
total_mb=$((total_kb / 1024))
log "Total RAM: ${total_mb} MB"

# Scale-down tuning for low-RAM devices
if [ "$total_mb" -lt 4096 ]; then
    SWAPPINESS=150
    MIN_FREE_KB=65536
    EXTRA_FREE_KB=32768
    log "Low-RAM arena. Adjusted tuning for ${total_mb}MB."
fi

# ============================================================
# PHASE 1: VIRTUAL MEMORY SCHEDULE
# ============================================================
log "--- Phase 1: vm scheduling ---"

# swappiness: 0=never swap (risky), 100=swap aggressively
# Default 60 too aggressive for AOSP. 40 keeps anon hot longer.
[ -w /proc/sys/vm/swappiness ] && {
    echo $SWAPPINESS > /proc/sys/vm/swappiness
    log "  vm.swappiness = $SWAPPINESS (was 60)"
}

# dirty_ratio: % of RAM allowed dirty before sync write
# Default 20 = sync stalls. 15 = smoother UI writes.
[ -w /proc/sys/vm/dirty_ratio ] && {
    echo $DIRTY_RATIO > /proc/sys/vm/dirty_ratio
    log "  vm.dirty_ratio = $DIRTY_RATIO"
}

# dirty_background_ratio: start writeback at this %
[ -w /proc/sys/vm/dirty_background_ratio ] && {
    echo $DIRTY_BG_RATIO > /proc/sys/vm/dirty_background_ratio
    log "  vm.dirty_background_ratio = $DIRTY_BG_RATIO"
}

# vfs_cache_pressure: tendency to reclaim inode/dentry cache
# Default 100 = aggressive reclaim. 80 = keep cache for app restarts.
[ -w /proc/sys/vm/vfs_cache_pressure ] && {
    echo $VFS_CACHE_PRESSURE > /proc/sys/vm/vfs_cache_pressure
    log "  vm.vfs_cache_pressure = $VFS_CACHE_PRESSURE"
}

# min_free_kbytes: always keep this much free for atomic allocs
# Default ~64MB on 8GB. 128MB helps kswapd start earlier.
[ -w /proc/sys/vm/min_free_kbytes ] && {
    echo $MIN_FREE_KB > /proc/sys/vm/min_free_kbytes
    log "  vm.min_free_kbytes = ${MIN_FREE_KB} KB"
}

# extra_free_kbytes: extra cushion beyond min_free
[ -w /proc/sys/vm/extra_free_kbytes ] && {
    echo $EXTRA_FREE_KB > /proc/sys/vm/extra_free_kbytes
    log "  vm.extra_free_kbytes = ${EXTRA_FREE_KB} KB"
}

# page-cluster: controls page read-ahead from swap (0 is optimal for ZRAM)
[ -w /proc/sys/vm/page-cluster ] && {
    echo 0 > /proc/sys/vm/page-cluster
    log "  vm.page-cluster = 0"
}

# ============================================================
# PHASE 2: ZRAM COMPRESSION
# ============================================================
log "--- Phase 2: zram compression ---"
ZRAM_DEV=$(ls /sys/block/ 2>/dev/null | grep -E "^zram" | head -1)
if [ -n "$ZRAM_DEV" ] && [ -f /sys/block/$ZRAM_DEV/comp_algorithm ]; then
    avail_algo=$(cat /sys/block/$ZRAM_DEV/comp_algorithm)
    # Detect if zram has data (algorithm can only change when empty)
    if [ -f /sys/block/$ZRAM_DEV/mm_stat ]; then
        used_bytes=$(awk '{print $1}' /sys/block/$ZRAM_DEV/mm_stat 2>/dev/null)
    else
        used_bytes=999999
    fi

    if [ "${used_bytes:-0}" -gt 0 ] 2>/dev/null; then
        # zram in use, can't change algo/streams
        current=$(echo "$avail_algo" | tr -d '[]' | awk '{print $1}')
        log "  $ZRAM_DEV in use (${used_bytes} bytes) — algo/streams locked"
        log "  Active: $current (tune in init.rc for boot-time change)"
    else
        # zram empty, safe to change
        if echo "$avail_algo" | grep -q "zstd"; then
            if echo zstd > /sys/block/$ZRAM_DEV/comp_algorithm 2>/dev/null; then
                log "  $ZRAM_DEV algo: zstd (best ratio)"
            else
                log "  $ZRAM_DEV algo: write failed"
            fi
        elif echo "$avail_algo" | grep -q "lz4"; then
            if echo lz4 > /sys/block/$ZRAM_DEV/comp_algorithm 2>/dev/null; then
                log "  $ZRAM_DEV algo: lz4 (fast)"
            else
                log "  $ZRAM_DEV algo: write failed"
            fi
        else
            current=$(echo "$avail_algo" | tr -d '[]' | awk '{print $1}')
            log "  $ZRAM_DEV algo: $current (no preferred available)"
        fi

        # Streams: ncpu/2 is sweet spot (too many = contention, too few = bottleneck)
        ncpu=$(grep -c ^processor /proc/cpuinfo 2>/dev/null)
        [ -z "$ncpu" ] || [ "$ncpu" -lt 2 ] && ncpu=4
        streams=$((ncpu / 2))
        [ "$streams" -lt 1 ] && streams=1
        if [ -f /sys/block/$ZRAM_DEV/max_comp_streams ]; then
            if echo $streams > /sys/block/$ZRAM_DEV/max_comp_streams 2>/dev/null; then
                log "  $ZRAM_DEV streams: $streams (cpus=$ncpu)"
            else
                log "  $ZRAM_DEV streams: write failed"
            fi
        fi
    fi
else
    log "  No zram device found (skipped)"
fi

# ============================================================
# PHASE 3: I/O SCHEDULER PER DEVICE
# ============================================================
# v1.0.1: Trust kernel's compiled-in schedulers. If preferred is not in
# the kernel, write will silently fail and current remains. Just check
# the file content to see what's available before attempting.
log "--- Phase 3: I/O scheduler ---"
for dev in /sys/block/mmcblk* /sys/block/sd*; do
    [ ! -d "$dev" ] && continue
    devname=$(basename "$dev")
    sched_file="$dev/queue/scheduler"
    [ ! -f "$sched_file" ] && continue

    # File format: [active] available1 available2 ...
    sched_content=$(cat "$sched_file" 2>/dev/null)
    current_sched=$(echo "$sched_content" | tr -d '[]' | awk '{print $1}')

    case "$devname" in
        mmcblk*|mmcblk*rpmb|mmcblk*boot*)
            # eMMC: mq-deadline is the sweet spot for budget SoC
            preferred="mq-deadline"
            ;;
        sd*)
            # SD card: bfq gives better fairness for removable media
            preferred="bfq"
            [ "$preferred" = "bfq" ] && ! echo "$sched_content" | grep -q "bfq" && preferred="mq-deadline"
            ;;
        *)
            preferred="mq-deadline"
            ;;
    esac

    if [ "$current_sched" = "$preferred" ]; then
        log "  $devname: $current_sched (optimal)"
    else
        # Try to set preferred. Kernel will reject if not available.
        if echo "$preferred" > "$sched_file" 2>/dev/null; then
            # Verify the change took effect
            new_sched=$(cat "$sched_file" 2>/dev/null | tr -d '[]' | awk '{print $1}')
            log "  $devname: $current_sched -> $new_sched"
        else
            log "  $devname: $current_sched (no change - $preferred unavailable)"
        fi
    fi
done

log "--- Referee schedule set. Match can begin. ---"
touch "$APPLIED_FLAG"
