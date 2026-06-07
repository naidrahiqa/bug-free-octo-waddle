#!/system/bin/sh
echo "=== 1. getprop NTFS-related ==="
getprop | grep -iE "ntfs|fuse|sdcard|otg|usb" | head -20

echo ""
echo "=== 2. fstab configuration ==="
cat /vendor/etc/fstab.mt6781 2>/dev/null | head -30
echo "--- system fstab ---"
cat /system/etc/fstab* 2>/dev/null | head -20
echo "--- /proc/mounts all ==="
cat /proc/mounts | grep -v "^proc\|^sysfs\|^tmpfs\|^cgroup\|^none\|^devpts\|^selinuxfs\|^tracefs\|^bpf\|^pstore\|^debugfs\|^configfs\|^fusectl\|^functionfs\|^dev/mnt" | head -30

echo ""
echo "=== 3. init.d / module.d scripts (ntfs related) ==="
ls /system/etc/init.d/ 2>/dev/null
ls /data/adb/modules/*/service.sh 2>/dev/null
echo "--- searching ntfs in init scripts ---"
for f in /system/etc/init/*.rc /vendor/etc/init/*.rc /system/etc/init.d/*.sh /data/adb/modules/*/service.sh /data/adb/modules/*/post-fs-data.sh; do
  if [ -f "$f" ] && grep -lE "ntfs|mount" "$f" >/dev/null 2>&1; then
    echo "FOUND in: $f"
    grep -nE "ntfs|mount" "$f" | head -3
  fi
done

echo ""
echo "=== 4. vold / sdcard daemon status ==="
ps -A 2>/dev/null | grep -E "vold|sdcard|fsck"
echo "--- vold fstab ---"
cat /system/etc/vold.fstab 2>/dev/null | head -20
