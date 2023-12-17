#!/usr/bin/env python3
# -*- coding: utf-8 -*- 

# MQTT
import paho.mqtt.client as mqtt
import config
from time import sleep

import json

import subprocess
 
verbose = 1

def on_connect(client, userdata, flag, rc):
    print("Connected with result code " + str(rc), flush=True)
 
def on_disconnect(client, userdata, rc):
    print("Disconnected", flush=True)
    if rc != 0:
        print("Unexpected disconnection.", flush=True)
        try:
            client.reconnect()
        except:
            print("Failed to reconnect", flush=True)
 
def on_publish(client, userdata, mid):
    if verbose > 1:
        print("publish: {0}".format(mid), flush=True)
 
def on_log(client, userdata, level, buff):
    if verbose > 1:
        print(buff, flush=True);

def main():
    # MQTT
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_disconnect = on_disconnect
    client.on_publish = on_publish
    client.on_log = on_log
    client.username_pw_set(config.username, config.password)
    client.connect(config.broker, 1883, 60) 

    data = {}
    data["device"] = "radio"
    data["title"] = ""
    title1 = ""
    title2 = ""
    title3 = ""
    hist_title = ["", "", ""]
    hist_idx = 0
    hist_max = 3

    client.loop_start()
    try:
        while True:
            # Get info
            res = subprocess.run(["qdbus",
                "org.mpris.MediaPlayer2.Goodvibes",
                "/org/mpris/MediaPlayer2",
                "org.mpris.MediaPlayer2.Player.Metadata"],
                capture_output=True, text=True)
            #print(res.stdout)
            for line in res.stdout.split("\n"):
                if "xesam:title:" in line:
                    newtitle = line[13:]
                    if newtitle != hist_title[hist_idx]:
                        hist_idx = (hist_idx + 1) % hist_max
                        hist_title[hist_idx] = newtitle
                    if True:
                        data["title"] = " / ".join(hist_title)
                        if verbose > 1:
                            print(data, flush=True)
                        #print(json.dumps(data))
                        client.publish("room1/radio", format(json.dumps(data)))
            sleep(5)
    except KeyboardInterrupt:
        # Exit
        print("Exit")
 
if __name__ == '__main__':
    main()
