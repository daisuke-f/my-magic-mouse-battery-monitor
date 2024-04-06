#!/bin/bash

log() {
  echo '['`date "+%Y-%m-%d %H:%M:%S"`']' "$1"
}

log "Start sending"

# configuration variables
SERVER=192.168.0.1
PORT=10051
HOST_KEY="mymac"
MOUSE_KEY="mouse.battery"
KEYBOARD_KEY="keyboard.battery"

# get battery levels
mouse_level=$(
  ioreg -a -r -n AppleDeviceManagementHIDEventService \
  | xmllint --xpath '/plist/array/dict/key[text()="Product"]/following-sibling::*[1][text()="Magic Mouse"]/../key[text()="BatteryPercent"]/following-sibling::*[1]/text()' -
)

keyboard_level=$(
  ioreg -a -r -n AppleDeviceManagementHIDEventService \
  | xmllint --xpath '/plist/array/dict/key[text()="Product"]/following-sibling::*[1][text()="Magic Keyboard"]/../key[text()="BatteryPercent"]/following-sibling::*[1]/text()' -
)

# create JSON containing monitored data
# @see https://www.zabbix.com/documentation/current/en/manual/appendix/items/trapper
data=$(
  printf \
    '{"request":"sender data","data":[{"host":"%s","key":"%s","value":"%s"},{"host":"%s","key":"%s","value":"%s"}]}' \
    "$HOST_KEY" "$MOUSE_KEY" "$mouse_level" \
    "$HOST_KEY" "$KEYBOARD_KEY" "$keyboard_level"
)

# build entire message and send it to our zabbix server/proxy
# @see https://www.zabbix.com/documentation/current/en/manual/appendix/protocols/header_datalen
datalen=$(printf "%08x" ${#data})
datalen="\\x${datalen:6:2}\\x${datalen:4:2}\\x${datalen:2:2}\\x${datalen:0:2}"

resp=`printf "ZBXD\1${datalen}\0\0\0\0%s" "$data" | nc "$SERVER" "$PORT"`

log "Response: $resp"
