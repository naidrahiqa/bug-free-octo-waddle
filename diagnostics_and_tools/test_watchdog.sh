#!/system/bin/sh
# Final verification: check staged watchdog has all critical patterns
echo "=== Staged watchdog patterns (modules_update) ==="
f=/data/adb/modules_update/waguri-my-bini/watchdog.sh

# Count pattern categories
echo "  encore protection: $(grep -c 'encore' $f)"
echo "  network protection: $(grep -c 'network' $f)"
echo "  gamespace protection: $(grep -c 'gamespace' $f)"
echo "  mediacodec protection: $(grep -c 'media' $f)"
echo "  threshold (should be 900s): $(grep 'MIN_UPTIME=' $f)"
echo "  max kill per cycle: $(grep 'MAX_KILL_PER_CYCLE=' $f)"
echo "  self PID skip: $(grep 'SELF_PID' $f)"
echo "  version: $(grep -oE 'v1\.[0-9.]+' $f | head -1)"
echo ""
echo "=== module.prop version ==="
cat /data/adb/modules_update/waguri-my-bini/module.prop | head -3
