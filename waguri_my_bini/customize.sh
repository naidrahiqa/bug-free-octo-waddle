ui_print "==============================================="
ui_print "             WAGURI MY BINI                    "
ui_print "         Stability & ROM Bug Fix              "
ui_print "==============================================="
ui_print "  v1.0-ksunext | Redmi 12 (Helio G88)         "
ui_print "  Target: KernelSU Next                       "
ui_print "==============================================="

ui_print "- Setting script permissions..."
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/watchdog.sh" 0 0 0755

ui_print "- Watchdog v1.0: skip D-state, PROTECT your games."
ui_print "- Kill cooldown 10m to avoid log spam."
ui_print "- Media scan + Rescue Party disable (v1.2)."
ui_print "- Boot protection (v1.2)."
