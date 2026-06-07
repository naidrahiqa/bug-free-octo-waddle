#!/system/bin/sh
# Hyacine Fuse v1.3-ksunext - BDI by major number
# FIX: /sys/class/bdi/ uses major:minor (179:0), not device names. Filter by major.
LOGFILE="/data/local/tmp/hyacine_fuse.log"

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 10; done

log "Hyacine Fuse: Enabling FUSE Passthrough..."
# Enable FUSE Passthrough to prevent userspace FUSE daemon deadlocks (D-state) and speed up I/O
resetprop persist.sys.fuse.passthrough.enable true 2>/dev/null
log "  persist.sys.fuse.passthrough.enable = true"

log "Hyacine Fuse: Tuning I/O read-ahead..."

COUNT=0
for bdi in /sys/class/bdi/*; do
    NAME=$(basename "$bdi")

    # Extract major number from "MAJOR:MINOR" format
    MAJOR="${NAME%%:*}"

    # Only tune real physical disks:
    # 179 = MMC block (mmcblk*, all partitions including userdata)
    # 8   = SCSI/SATA (sda*, external SD over USB)
    case "$MAJOR" in
        179|8)
            if [ -f "$bdi/read_ahead_kb" ] && echo 1024 > "$bdi/read_ahead_kb" 2>/dev/null; then
                log "  Tuned read-ahead: $NAME (major $MAJOR) -> 1024 KB"
                COUNT=$((COUNT + 1))
            fi
            ;;
    esac
done
log "Done. $COUNT device(s) read-ahead tuned."

log "Hyacine Fuse: Tuning block queues..."
Q_COUNT=0
for dev in /sys/block/mmcblk* /sys/block/sd*; do
    [ ! -d "$dev" ] && continue
    devname=$(basename "$dev")
    # Skip virtual boot/rpmb partitions to avoid locking overhead
    case "$devname" in
        mmcblk*boot*|mmcblk*rpmb)
            continue ;;
    esac

    [ -f "$dev/queue/nr_requests" ] && echo 128 > "$dev/queue/nr_requests" 2>/dev/null
    [ -f "$dev/queue/nomerges" ] && echo 0 > "$dev/queue/nomerges" 2>/dev/null
    [ -f "$dev/queue/add_random" ] && echo 0 > "$dev/queue/add_random" 2>/dev/null
    log "  Tuned Queue: $devname (nr_requests=128, nomerges=0, add_random=0)"
    Q_COUNT=$((Q_COUNT + 1))
done
log "Done. $Q_COUNT block device queue(s) tuned."
exit 0
