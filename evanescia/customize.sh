ui_print "==============================================="
ui_print "              EVANESCIA                       "
ui_print "       Memory Referee | Planarcadia           "
ui_print "==============================================="
ui_print "  v1.0-ksunext | Redmi 12 (Helio G88)       "
ui_print "  Target: KernelSU Next                       "
ui_print "  Companion: castorice / hyacine / waguri    "
ui_print "==============================================="

ui_print "- Setting script permissions..."
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "- Referee schedules the match (pre-boot):"
ui_print "  vm.swappiness -> 120 (150 on low-RAM)"
ui_print "  vm.dirty_ratio 20 -> 15"
ui_print "  vm.vfs_cache_pressure 100 -> 80 (locked)"
ui_print "  vm.min_free_kbytes -> 128MB (locked)"
ui_print "  zram: zstd/lz4 + tuned streams"
ui_print "  I/O scheduler: mq-deadline for eMMC"

ui_print "- Referee in arena (runtime):"
ui_print "  Yellow card <15% avail: gentle reclaim"
ui_print "  Red card <8% avail: drop page cache"
ui_print "- v1.0: Force swappiness (120/150) & VM lock in service.sh"

ui_print "- Disable: touch /data/local/tmp/evanescia_disable"
