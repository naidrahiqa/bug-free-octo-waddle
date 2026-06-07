echo "=== ps for our watchdog ==="
ps -ef | grep -E "watchdog\.sh" | grep -v kthread
echo ""
echo "=== log last 5 lines ==="
tail -5 /data/local/tmp/waguri_watchdog.log
echo ""
echo "=== memory snapshot ==="
free -m | head -3
echo ""
echo "=== top 5 RSS ==="
ps -A -o NAME,RSS | sort -k2 -n -r | head -6
