#!/system/bin/sh
# Castorice Thermal v1.3 - Overkill Edition
# Focus: Total Thermal Bypass, Bind-Mount Binary Deletion, JEITA Disable

MODDIR=${0%/*}
LOGFILE="/data/local/tmp/castorice_thermal.log"

log() {
    local msg="[CASTORICE-OVERKILL] $(date '+%m-%d %H:%M:%S') $*"
    echo "$msg" >> "$LOGFILE"
}

wait_boot() {
    while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
}

# --- SECTION 2: FORCE CHARGING (DEEP BYPASS) ---
fix_charging() {
    # 1. Reset ALL Cooling Devices (Force state 0)
    for cd in /sys/class/thermal/cooling_device*; do
        [ -f "$cd/cur_state" ] && chmod 644 "$cd/cur_state" 2>/dev/null && echo 0 > "$cd/cur_state" 2>/dev/null
    done

    # 2. Disable MTK PPM Thermal Policy
    if [ -f "/proc/ppm/policy_status" ]; then
        echo "5 0" > /proc/ppm/policy_status 2>/dev/null # Disable PPM_POLICY_THERMAL
        log "PPM Thermal Policy disabled."
    fi

    # 3. Disable JEITA Protection (Sensitive charging limits)
    if [ -f "/sys/devices/platform/charger/sw_jeita" ]; then
        chmod 644 /sys/devices/platform/charger/sw_jeita 2>/dev/null
        echo 0 > /sys/devices/platform/charger/sw_jeita 2>/dev/null
    fi

    # 4. Force MTK Charger Nodes
    local chg_p="/sys/devices/platform/charger"
    if [ -d "$chg_p" ]; then
        for node in Pump_Express enable_sc input_current pdc_max_watt; do
            if [ -f "$chg_p/$node" ]; then
                chmod 644 "$chg_p/$node" 2>/dev/null
                case "$node" in
                    Pump_Express|enable_sc) echo 1 > "$chg_p/$node" 2>/dev/null ;;
                    input_current) echo 5000 > "$chg_p/$node" 2>/dev/null ;;
                    pdc_max_watt) echo 33000000 > "$chg_p/$node" 2>/dev/null ;;
                esac
            fi
        done
    fi

    # 5. Xiaomi Specific Props
    setprop persist.vendor.charge.fastcharge 1 2>/dev/null
    setprop persist.vendor.smart_chg.turbo 1 2>/dev/null
    echo 10 > /sys/class/thermal/thermal_message/sconfig 2>/dev/null
}

# --- MAIN ---
wait_boot
sleep 15
log "===== Castorice Thermal v1.3.1 (Fixed) starting ====="

fix_charging

# RAPID LOOP (Every 15 seconds to ensure no rollback)
(
    while true; do
        # Force cooling devices to 0
        for cd in /sys/class/thermal/cooling_device*; do
            [ -f "$cd/cur_state" ] && echo 0 > "$cd/cur_state" 2>/dev/null
        done
        
        # Keep input_suspend off
        [ -f /sys/class/power_supply/battery/input_suspend ] && echo 0 > /sys/class/power_supply/battery/input_suspend 2>/dev/null
        
        sleep 15
    done
) &

log "Thermal logic active. Watch the mA climb."
