#!/system/bin/sh
echo "=== 7. Memory leaks / fragmentation ==="
echo "--- DMA-BUF / Graphics ---"
dumpsys meminfo --checkin 2>/dev/null | head -20
echo ""
echo "--- GPU memory ---"
dumpsys meminfo | grep -A 2 "Graphics\|EGL\|GL"
echo ""
echo "--- Top slab allocations (kernel) ==="
cat /proc/slabinfo 2>/dev/null | head -20
echo ""
echo "--- ION heaps (Mediatek) ==="
cat /proc/ion/heaps 2>/dev/null | head -30
echo ""
echo "--- zygote fork count (app process count) ==="
ps -A 2>/dev/null | wc -l
echo "--- Dalvik/ART processes ---"
ps -A 2>/dev/null | grep -c "com\."

echo ""
echo "=== 8. Cgroup memory pressure per-app ==="
for d in /dev/memcg /sys/fs/cgroup/memory /sys/fs/cgroup; do
  if [ -d "$d" ]; then
    echo "Found cgroup: $d"
    find "$d" -name "memory.usage_in_bytes" 2>/dev/null | head -3
    break
  fi
done

echo ""
echo "=== 9. Check all apps with Pss > 50 MB ==="
dumpsys meminfo 2>/dev/null | grep -E "^\s+[0-9,]+K:" | awk -F: '{gsub(/[KM,]/,"",$1); if($1+0 > 50000) print $0}' | head -20
