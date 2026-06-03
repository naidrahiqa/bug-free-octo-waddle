SKIPUNZIP=1
# Dynamic path detection for customize.sh
ui_print "**********************************************"
ui_print "         _  _                                 "
ui_print "       _( )_  _      M Y                      "
ui_print "      (     )( )_     K A O R U K O           "
ui_print "     (   _   )   )                            "
ui_print "      (_( )_) _ )                             "
ui_print "         (_) ( )      - Smooth Edition -      "
ui_print "                                              "
ui_print "**********************************************"
ui_print "  > Environment: Dynamic Path Detection       "
ui_print "  > Target: UI Smoothness & ROM Stability     "
ui_print "  > Version: v1.3.1 (Hotfix)                  "
ui_print "**********************************************"

ui_print "- Blooming the garden (extracting)..."
unzip -o "$ZIPFILE" 'module.prop' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'service.sh' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'post-fs-data.sh' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'banner.png' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'web_banner.png' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'webui/*' -d "$MODPATH" >&2

# Permissions
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755

ui_print "                                              "
ui_print "   \"Pindah-pindah sekarang lancar kok...\"   "
ui_print "              - Waguri Kaoruko                "
ui_print "                                              "
ui_print "**********************************************"
