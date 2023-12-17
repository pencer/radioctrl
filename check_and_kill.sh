#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: script <Bluetooth MAC> <programname>"
  echo "  Bluetooth MAC: MAC address to be checked using bluetoothctl"
  echo "  programname: process name to be checked (ex. mpg123)"
  exit
fi

BTMAC=$1
PROGNAME=$2

DEVNULL=/dev/null

check_conn () {
  bluetoothctl << EOF | grep 'Connected: no' >> $DEVNULL
info ${BTMAC}
quit
EOF
}

CHK=`ps -ef | grep ${PROGNAME} | grep -v grep | grep -v ${0##*/}`
RETVAL=$? # 1: not found, 0: found
if [ $RETVAL -eq 0 ]; then
  echo $CHK >> $DEVNULL
  CNT=5
  while [ $CNT -gt 0 ]; do
    let CNT="$CNT-1"
    check_conn
    if [ $? -ne 0 ]; then
        echo "non KILL" >> $DEVNULL
	exit
    else
      echo "CHECK" >> $DEVNULL
    fi
    sleep 5
  done
  echo "Going to kill ${PROGNAME}" >> $DEVNULL
  PID=`echo $CHK | awk '{print $2}'`
  kill -HUP $PID
  echo "Sent HUP to PID=$PID" >> $DEVNULL
fi

