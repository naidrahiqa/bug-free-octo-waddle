#!/system/bin/sh
# Castorice Thermal v1.6-ksunext - Charge control fix for HyperOS/G88
# FIX: Device uses charge_control_limit (USB Charging spec) instead of constant_charge_current.
LOGFILE="/data/local/tmp/castorice_thermal.log"

log() {
    echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOGFILE"
}

# Find battery node (where charge_control_limit lives on modern MTK)
discover_battery_path() {
    for ps in /sys/class/power_supply/*; do
        [ -f "$ps/type" ] || continue
        local t=$(cat "$ps/type" 2>/dev/null)
        if [ "$t" = "Battery" ]; then
            echo "$ps"
            return
        fi
    done
}

# Plugged if any non-battery supply online=1
is_plugged() {
    for ps in /sys/class/power_supply/*; do
        [ -f "$ps/type" ] || continue
        local t=$(cat "$ps/type" 2>/dev/null)
        [ "$t" = "Battery" ] && continue
        [ -f "$ps/online" ] || continue
        if [ "$(cat "$ps/online" 2>/dev/null)" = "1" ]; then
            return 0
        fi
    done
    return 1
}

apply_charging() {
    local BAT=$(discover_battery_path)
    [ -z "$BAT" ] && { log "ERROR: Battery node not found."; return 1; }

    log "Applying charging tweaks to: $BAT"

    # Method 1: charge_control_limit (Android 12+ USB Charging spec, MTK HyperOS G88)
    if [ -f "$BAT/charge_control_limit" ] && [ -f "$BAT/charge_control_limit_max" ]; then
        local MAX=$(cat "$BAT/charge_control_limit_max" 2>/dev/null)
        [ -n "$MAX" ] && [ "$MAX" -gt 0 ] 2>/dev/null && {
            echo "$MAX" > "$BAT/charge_control_limit" 2>/dev/null
            local NOW=$(cat "$BAT/charge_control_limit" 2>/dev/null)
            log "  charge_control_limit: $NOW / max $MAX"
        }
    fi

    # Method 2: constant_charge_current (legacy MTK, in case)
    if [ -f "$BAT/constant_charge_current" ]; then
        echo 3600000 > "$BAT/constant_charge_current" 2>/dev/null
        log "  constant_charge_current set to 3600000 uA"
    fi

    # Method 3: input_current_limit (legacy)
    if [ -f "$BAT/input_current_limit" ]; then
        echo 3600000 > "$BAT/input_current_limit" 2>/dev/null
        log "  input_current_limit set to 3600000 uA"
    fi

    # Platform charger tuning
    [ -f /sys/devices/platform/charger/pdc_max_watt ] && \
        echo 18000000 > /sys/devices/platform/charger/pdc_max_watt 2>/dev/null
    [ -f /sys/devices/platform/charger/fast_chg_en ] && \
        echo 1 > /sys/devices/platform/charger/fast_chg_en 2>/dev/null

    setprop persist.vendor.charge.fastcharge 1
    log "Charging tweaks applied OK."
}

is_screen_on() {
    if dumpsys power 2>/dev/null | grep -q "mWakefulness=Awake"; then
        return 0
    else
        return 1
    fi
}

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
sleep 20

log "Castorice Thermal v1.7-ksunext Active (Charging + Dynamic Performance)"

LAST_STATE="unknown"
SCREEN_STATE="unknown"
LOOP_COUNT=0

while true; do
    # 1. Screen state check (runs every 10s)
    if is_screen_on; then
        if [ "$SCREEN_STATE" != "ON" ]; then
            # Screen ON: Performance Unlock
            [ -f /proc/ppm/enabled ] && {
                echo "5 0" > /proc/ppm/policy_status 2>/dev/null # Disable Thermal Throttling
                echo "3 0" > /proc/ppm/policy_status 2>/dev/null # Disable Force Limit
                echo "4 0" > /proc/ppm/policy_status 2>/dev/null # Disable Power Throttling
            }
            # Unlock CPU to max hardware limits (1.8GHz LITTLE, 2.0GHz big)
            echo 1800000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null
            echo 2000000 > /sys/devices/system/cpu/cpu6/cpufreq/scaling_max_freq 2>/dev/null
            SCREEN_STATE="ON"
            log "Screen ON: PPM throttling bypassed, max CPU freqs unlocked."
        fi
    else
        if [ "$SCREEN_STATE" != "OFF" ]; then
            # Screen OFF: Deep Sleep Battery Saver
            [ -f /proc/ppm/enabled ] && {
                echo "5 1" > /proc/ppm/policy_status 2>/dev/null # Enable Thermal Throttling
                echo "3 1" > /proc/ppm/policy_status 2>/dev/null # Enable Force Limit
                echo "4 1" > /proc/ppm/policy_status 2>/dev/null # Enable Power Throttling
            }
            # Cap CPU freqs to save battery during sleep
            echo 1010000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null
            echo 1087000 > /sys/devices/system/cpu/cpu6/cpufreq/scaling_max_freq 2>/dev/null
            SCREEN_STATE="OFF"
            log "Screen OFF: PPM throttling enabled, CPU freqs capped for deep sleep."
        fi
    fi

    # 2. Charging check (runs every 30s)
    if [ $((LOOP_COUNT % 3)) -eq 0 ]; then
        if is_plugged; then
            CURRENT="plugged"
        else
            CURRENT="unplugged"
        fi

        if [ "$CURRENT" != "$LAST_STATE" ] || [ $((LOOP_COUNT % 30)) -eq 0 ]; then
            if [ "$CURRENT" = "plugged" ]; then
                apply_charging
            fi
            LAST_STATE="$CURRENT"
        fi
    fi

    LOOP_COUNT=$((LOOP_COUNT + 1))
    sleep 10
done
