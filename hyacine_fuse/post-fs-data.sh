#!/system/bin/sh
# Hyacine Fuse v1.5-ksunext - Early boot tuning
MODDIR=${0%/*}
LOGFILE="/data/local/tmp/hyacine_fuse.log"

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] [post-fs-data] $*" >> "$LOGFILE"
}

log "Setting FUSE Passthrough properties early..."
resetprop persist.sys.fuse.passthrough.enable true 2>/dev/null
resetprop sys.fuse.passthrough.enable true 2>/dev/null
