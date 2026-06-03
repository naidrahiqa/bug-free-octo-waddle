SKIPUNZIP=1

ui_print "**********************************************"
ui_print "          ____             _                 "
ui_print "         / ___|__ _ ___| |_ ___  _ __ ___ ___"
ui_print "        | |   / _' / __| __/ _ \| '__/ _ / __|"
ui_print "        | |__| (_| \__ | || (_) | | |  __\__ \\"
ui_print "         \____\__,_|___/\__\___/|_|  \___|___/"
ui_print "                                              "
ui_print "             THERMAL & FAST CHARGE            "
ui_print "**********************************************"
ui_print "  Identity: CASTORICE THERMAL                 "
ui_print "  Version: v1.0                               "
ui_print "  Focus: Gaming & Charging Boost              "
ui_print "**********************************************"

# Install files
ui_print "- Extracting module files..."
unzip -o "$ZIPFILE" 'service.sh' 'module.prop' -d "$MODPATH" >&2
unzip -o "$ZIPFILE" 'system/*' -d "$MODPATH" >&2

set_permission "$MODPATH/service.sh" 0 0 0755
ui_print "- Performance & Charging boost ready."
