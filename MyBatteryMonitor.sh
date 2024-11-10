#!/bin/bash

# Zabbix Server/Proxy config
SERVER=127.0.0.1
PORT=10051

# Zabbix Host/Item config
HOST_KEY="mymac"
MOUSE_KEY="mouse.battery"
KEYBOARD_KEY="keyboard.battery"

LOGGING=1

mylog() {
  if [ "$LOGGING" -ne 1 ]; then return; fi
  echo '['`date "+%Y-%m-%d %H:%M:%S"`']' "$1"
}

mylog "Start sending"

# get battery levels
mouse_level=$(
  ioreg -a -r -n AppleDeviceManagementHIDEventService \
  | xmllint --xpath '/plist/array/dict/key[text()="Product"]/following-sibling::*[1][text()="Magic Mouse" or text()="System Administrator’s Mouse"]/../key[text()="BatteryPercent"]/following-sibling::*[1]/text()' -
)

keyboard_level=$(
  ioreg -a -r -n AppleDeviceManagementHIDEventService \
  | xmllint --xpath '/plist/array/dict/key[text()="Product"]/following-sibling::*[1][text()="Magic Keyboard" or text()="System Administrator’s Keyboard"]/../key[text()="BatteryPercent"]/following-sibling::*[1]/text()' -
)

# create JSON containing monitored data
# @see https://www.zabbix.com/documentation/current/en/manual/appendix/items/trapper
data=$(
  printf \
    '{"request":"sender data","data":[{"host":"%s","key":"%s","value":"%s"},{"host":"%s","key":"%s","value":"%s"}]}' \
    "$HOST_KEY" "$MOUSE_KEY" "$mouse_level" \
    "$HOST_KEY" "$KEYBOARD_KEY" "$keyboard_level"
)

# build entire message
# @see https://www.zabbix.com/documentation/current/en/manual/appendix/protocols/header_datalen
datalen=$(printf "%08x" ${#data})
datalen="\\x${datalen:6:2}\\x${datalen:4:2}\\x${datalen:2:2}\\x${datalen:0:2}"

mylog "Request: $data"

# send the message to our zabbix server/proxy
resp=`printf "ZBXD\1${datalen}\0\0\0\0%s" "$data" | nc "$SERVER" "$PORT"`

rc=$?

mylog "Response: $resp"

exit $rc
