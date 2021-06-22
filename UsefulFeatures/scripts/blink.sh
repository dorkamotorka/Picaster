#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script requires root, run it again with sudo"
   exit 1
fi

sudo sh -c "echo none > /sys/class/leds/led0/trigger"

while true ; do
        sudo sh -c "echo 1 > /sys/class/leds/led0/brightness"
        sleep 1
        sudo sh -c "echo 0 > /sys/class/leds/led0/brightness"
        sleep 1
done
