#!/bin/bash
export XDG_RUNTIME_DIR=/run/user/1000

#whoami > /home/pi/work/radio/whoami.log
#echo $@ >> /home/pi/work/radio/whoami.log
#env >> /home/pi/work/radio/whoami.log

TARGETID= # empty by default
while [ $# -ge 1 ]; do
  TARGETID=$1
  shift
done

RADIOINFOFILE=/var/tmp/radioinfo.txt
RADIOIDFILE=/var/tmp/radioid.txt
RADIOID=1
# VRT URLs: https://www.vrt.be/nl/aanbod/kijk-en-luister/radio-luisteren/streamingslinks-radio/
RADIOURL[0]="http://icecast.vrtcdn.be/klaracontinuo-high.mp3"
RADIOURL[1]="http://icecast.vrtcdn.be/stubru_bruut-high.mp3"
RADIOURL[2]="http://icecast.vrtcdn.be/stubru-high.mp3"
RADIOURL[3]="http://icecast.vrtcdn.be/ketnetradio-high.mp3"
RADIOURL[4]="http://icecast.vrtcdn.be/mnm-high.mp3"
#RADIOURL[5]="/home/pi/Music/Wave.list"
RADIOURL[5]="http://ice1.somafm.com/u80s-128-mp3"
RADIOURL[6]="http://live-radio01.mediahubaustralia.com/JAZW/mp3/"
RADIOIDMAX=7

USE_MPG123=${USE_MPG123:-0}
if [ $USE_MPG123 -eq 1 ]; then
  CHK=`ps -ef | grep mpg123 | grep -v grep`
else
  CHK=`ps -ef | grep goodvibes | grep -v grep`
fi
RETVAL=$? # 1: not found, 0: found

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

  BTDEVICE=${BTDEVICE:-"-a bluealsa:DEV=6C:5A:B5:70:F8:2A"}
  echo BTDEVICE=$BTDEVICE

  VOLUME=10000
  if [ ${TARGETURL:0:4} == "http" ]; then
    if [ $USE_MPG123 -eq 1 ]; then
      curl -L $TARGETURL 2> /dev/null | /usr/bin/mpg123 --reopen -f $VOLUME $BTDEVICE - 2> $RADIOINFOFILE & 
    else
      goodvibes --without-ui $TARGETURL &
    fi
    echo "started"
  else
    echo FILE
    echo /usr/bin/mpg123 $TARGETURL $BTDEVICE 
    /usr/bin/mpg123 --list $TARGETURL $BTDEVICE  -
  fi
  echo $RADIOID > $RADIOIDFILE
  exit

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

