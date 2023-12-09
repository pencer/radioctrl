#!/bin/bash

RESTMP=result.tmp

function bt_pair () {
bluetoothctl << EOF
remove ${BTMAC}
EOF

sleep 5

bluetoothctl << EOF
scan on
EOF

sleep 5

bluetoothctl << EOF
pair ${BTMAC}
EOF

sleep 5

bluetoothctl << EOF
trust ${BTMAC}
connect ${BTMAC}
quit
EOF
}

function bt_connect () {
bluetoothctl << EOF
connect ${BTMAC}
quit
EOF
}

function check_devices () {
bluetoothctl << EOF > $RESTMP
info ${BTMAC}
quit
EOF
grep 'Connected: yes' $RESTMP
if [ $? -eq 1 ]; then
  # Not found
  return 1
else
  # Found
  return 0
fi
}

function show_usage () {
  echo "Usage: script <Bluetooth MAC> [conn|pair]"
  echo "  Bluetooth MAC: MAC address to be checked using bluetoothctl"
}

BTMAC=
while [ $# -ge 1 ]; do
  if [ $1 == "-h" ]; then
    show_usage
    exit
  elif [ $1 == "conn" ]; then
    bt_connect
  elif [ $1 == "pair" ]; then
    bt_pair
  else
    BTMAC=$1
  fi
  shift
done

exit
