#!/system/bin/sh
echo "=== 5. sgameGlobal state analysis ==="
echo "--- process state ---"
cat /proc/12743/status 2>/dev/null | head -25
echo ""
echo "--- wchan (what kernel function it's stuck in) ---"
cat /proc/12743/wchan 2>/dev/null
echo ""
echo "--- stack trace ---"
cat /proc/12743/stack 2>/dev/null | head -10
echo ""
echo "--- syscall ---"
cat /proc/12743/syscall 2>/dev/null
echo ""
echo "--- file descriptors open ---"
ls -la /proc/12743/fd 2>/dev/null | head -20

echo ""
echo "=== 6. mount.ntfs state analysis ==="
cat /proc/5182/status 2>/dev/null | head -15
echo "--- wchan ---"
cat /proc/5182/wchan 2>/dev/null
echo ""
cat /proc/5182/stack 2>/dev/null | head -10
echo ""
cat /proc/5182/syscall 2>/dev/null
echo "--- /proc/5182/fd ---"
ls -la /proc/5182/fd 2>/dev/null | head -10
echo "--- /proc/5182/cwd ---"
ls -la /proc/5182/cwd 2>/dev/null
