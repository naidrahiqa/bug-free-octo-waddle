ui_print "==============================================="
ui_print "             HYACINE FUSE                      "
ui_print "         Storage & I/O Optimization            "
ui_print "==============================================="
ui_print "  v1.0-ksunext | Redmi 12 (Helio G88)         "
ui_print "  Target: KernelSU Next                       "
ui_print "==============================================="

ui_print "- Setting service permissions..."
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
