#!/bin/sh
killall retroarch
sleep 1
killall simplermenu_plus
display_image /mnt/card/cfw/resources/shutdown-${SCREEN_WIDTH}x${SCREEN_HEIGHT}.bmp
sync
sleep 2
poweroff
