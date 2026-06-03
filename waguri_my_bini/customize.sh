SKIPUNZIP=1

ui_print "**********************************************"
ui_print "    __        __                         _    "
ui_print "    \ \      / /_ _  __ _ _   _ _ __(_)   "
ui_print "     \ \ /\ / / _' |/ _' | | | | '__| |   "
ui_print "      \ V  V / (_| | (_| | |_| | |  | |   "
ui_print "       \_/\_/ \__,_|\__, |\__,_|_|  |_|   "
ui_print "                    |___/                 "
ui_print "               MY BINI EDITION                "
ui_print "**********************************************"
ui_print "  Identity: WAGURI MY BINI                    "
ui_print "  Version: v1.0                               "
ui_print "  Focus: Stability & ROM Bug Fix              "
ui_print "**********************************************"

# Install files
ui_print "- Extracting module files..."
unzip -o "$ZIPFILE" 'service.sh' 'module.prop' 'watchdog.sh' 'post-fs-data.sh' 'sepolicy.rule' -d "$MODPATH" >&2

set_permission "$MODPATH/service.sh" 0 0 0755
set_permission "$MODPATH/watchdog.sh" 0 0 0755
set_permission "$MODPATH/post-fs-data.sh" 0 0 0755

ui_print "- PIN lock bug fixed (Watchdog whitelist)."
ui_print "- App logouts prevented."
ui_print "- System stability enhanced."
