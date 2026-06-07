#!/system/bin/sh
echo "=== Top PSS consumers (clean) ==="
dumpsys meminfo 2>/dev/null | awk '
/^ *[0-9,]+K: *[a-zA-Z]/ {
  size = $1
  gsub(/K,/, "", size)
  gsub(/K:/, "", size)
  size = size + 0
  name = ""
  for (i = 2; i <= NF; i++) {
    if ($i ~ /^[a-zA-Z]/) name = name " " $i
  }
  if (size > 50000) printf "%8d KB  %s\n", size, name
}' | sort -rn | head -15

echo ""
echo "=== Load Average & Running ==="
uptime
cat /proc/loadavg
echo "---"
echo "D-state process count:"
ps -A -o stat= 2>/dev/null | grep -c "^D"
echo "R-state process count:"
ps -A -o stat= 2>/dev/null | grep -c "^R"
echo "S-state process count:"
ps -A -o stat= 2>/dev/null | grep -c "^S"

echo ""
echo "=== IOWait & swap pressure ==="
echo "pgmajfault: $(grep pgfault /proc/vmstat | head -1)"
echo "pgmajfault: $(grep pgmajfault /proc/vmstat)"
echo "pswpin: $(grep pswpin /proc/vmstat)"
echo "pswpout: $(grep pswpout /proc/vmstat)"

echo ""
echo "=== Kernel slab top 5 ==="
cat /proc/slabinfo 2>/dev/null | head -8
