#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/1000

TARGETID= # empty by default
while [ $# -ge 1 ]; do
  TARGETID=$1
  shift
done

CHK=`ps -ef | grep mpg123 | grep -v grep`
RETVAL=$? # 1: not found, 0: found
RADIOIDFILE=/var/tmp/radioid.txt
RADIOINFOFILE=/var/tmp/radioinfo.txt
RADIOID=1
RADIOURL[0]="http://icecast.vrtcdn.be/klaracontinuo-high.mp3"
RADIOURL[1]="http://icecast.vrtcdn.be/stubru_bruut-high.mp3"
RADIOURL[2]="http://icecast.vrtcdn.be/stubru-high.mp3"
RADIOURL[3]="http://icecast.vrtcdn.be/ketnetradio-high.mp3"
RADIOURL[4]="http://icecast.vrtcdn.be/mnm-high.mp3"
RADIOURL[5]="/home/pi/Music/Wave.list"
RADIOURL[6]="http://live-radio01.mediahubaustralia.com/JAZW/mp3/"
RADIOIDMAX=7

echo RETVAL=$RETVAL

if [ $RETVAL -eq 1 ]; then
  CURID=`cat $RADIOIDFILE`
  echo CURID=$CURID
  if [ "$TARGETID" != "" ]; then
    NEXTID=$TARGETID
  else
    NEXTID=$(( $CURID + 1 ))
  fi
  RADIOID=$(( $NEXTID % $RADIOIDMAX ))
  echo RADIOID=$RADIOID
  TARGETURL=${RADIOURL[$RADIOID]}
  echo $TARGETURL
  if [ $? -eq 0 ]; then
    # Bluetooth Speaker Connected
    BTDEVICE="-a bluealsa:DEV=6C:5A:B5:70:F8:2A"
  else
    BTDEVICE=""
  fi
  VOLUME=5
  if [ ${TARGETURL:0:4} == "http" ]; then
    curl -L $TARGETURL 2> /dev/null | /usr/bin/mpg123 --reopen --gain $VOLUME $BTDEVICE - 2> $RADIOINFOFILE & 
  else
    echo FILE
    echo /usr/bin/mpg123 $TARGETURL $BTDEVICE 
    /usr/bin/mpg123 --list $TARGETURL $BTDEVICE  -
  fi
  echo $RADIOID > $RADIOIDFILE
  if [ "$BTDEVICE" != "" ]; then
    sleep 15
    # check
    dbus-send --system --print-reply --dest=org.bluez / org.freedesktop.DBus.ObjectManager.GetManagedObjects | grep State -A 1 | grep idle
    if [ $? -eq 0 ]; then
      # playing but idle
      # stop mpg123
      PID=`echo $CHK | awk '{print $2}'`
      kill $PID
    fi
  fi
else
  PID=`echo $CHK | awk '{print $2}'`
  kill -HUP $PID
fi

