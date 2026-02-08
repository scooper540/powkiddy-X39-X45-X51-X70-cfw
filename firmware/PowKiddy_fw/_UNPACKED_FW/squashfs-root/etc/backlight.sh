#!/bin/sh

bl_power="/sys/class/backlight/owl_backlight/bl_power"

if [ $1 = open ];then
    echo 0 > $bl_power
fi

if [ $1 = close ];then
    echo 1 > $bl_power
fi
