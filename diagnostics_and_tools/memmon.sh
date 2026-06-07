#!/system/bin/sh
# Mem Monitor - snapshot ringkas
echo "===== $(date '+%H:%M:%S') ====="

# Memory
meminfo=$(cat /proc/meminfo)
total=$(echo "$meminfo" | awk '/^MemTotal:/{print $2}')
free=$(echo "$meminfo" | awk '/^MemFree:/{print $2}')
avail=$(echo "$meminfo" | awk '/^MemAvailable:/{print $2}')
cached=$(echo "$meminfo" | awk '/^Cached:/{print $2}')
anon=$(echo "$meminfo" | awk '/^AnonPages:/{print $2}')
mlock=$(echo "$meminfo" | awk '/^Mlocked:/{print $2}')
swap_total=$(echo "$meminfo" | awk '/^SwapTotal:/{print $2}')
swap_free=$(echo "$meminfo" | awk '/^SwapFree:/{print $2}')
swap_used=$((swap_total - swap_free))

avail_pct=$((avail * 100 / total))
swap_pct=$((swap_used * 100 / swap_total))
used=$((total - avail))
used_pct=$((used * 100 / total))

echo "RAM:  ${avail_pct}% free | used=${used_pct}% | avail=$((avail/1024))M | free=$((free/1024))M | cached=$((cached/1024))M | anon=$((anon/1024))M | mlock=$((mlock/1024))M"
echo "SWAP: ${swap_pct}% | used=$((swap_used/1024))M / $((swap_total/1024))M"

# Pressure
echo "Pressure (some/full avg10): $(cat /proc/pressure/memory 2>/dev/null | awk -F'avg10=' 'NR==1{print $2}' | awk '{print $1}') / $(cat /proc/pressure/memory 2>/dev/null | awk -F'avg10=' 'NR==2{print $2}' | awk '{print $1}')"

# D-state count
d_state=$(ps -A -o stat= 2>/dev/null | grep -c "^D")
r_state=$(ps -A -o stat= 2>/dev/null | grep -c "^R")
load=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
echo "Proc: D=$d_state R=$r_state | Load: $load"

# Top 5 RAM
echo "Top RSS:"
ps -A -o PID,NAME,RSS 2>/dev/null | sort -k3 -rn | head -5 | awk '{printf "  %6s KB  %s\n", $3, $2}'

# Major faults rate
echo "Major faults total: $(grep pgmajfault /proc/vmstat | awk '{print $2}')"
echo ""
