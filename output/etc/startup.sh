#!/bin/sh
#start watchdog
mount /dev/mmcblk0p1 /mnt/card/
export PATH=$PATH:/usr/local/bin:/mnt/card/cfw/java/bin
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/mnt/card/cfw/libs
watchdog_feeder 5 30 &

# unload and reload adcjoystick to get the controls
rmmod owl_gpio_matrix_adcjoystick 2>/dev/null
insmod /mnt/original/lib/modules/3.10.0/owl_gpio_matrix_adcjoystick.ko tiny_mode=0

#only cpu0 is needed
echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 900000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

/etc/backlight.sh open &
#tinymix 35 1 &
export SOUND_PROCESS_LIST=retroarch
tinymix 30 1 &
tinymix 35 1 &
tinymix 15 20 &

#set correct values for good sound
echo "2 0x0223" > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
echo "0 0x0022" > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
echo "3 0xbebe" > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
echo "5 0x0468"  > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
echo "7 0x26BF"  > /sys/kernel/debug/asoc/s900_link/atc260x-audio/codec_reg
tinyplay /mnt/card/cfw/resources/welcome.wav &

export HOME=/mnt/card
export SDL_VIDEODRIVER=fbcon
export SMP_BASEPATH=/mnt/card/cfw/simplermenu_plus
export SMP_STATEFILE=/tmp/.state
export RA_CONFIG=/mnt/card/cfw/retroarch/retroarch.cfg
export SDL_NOMOUSE=1
export SDL_MOUSEDEV=/dev/null
#export SDL_VIDEO_FBCON_ROTATION=CCW
export SDL_AUDIODRIVER=alsa
export SDL_AUDIO_ALSA_DEBUG=0
export SDL_AUDIO_ALLOW_FREQUENCY_CHANGE=0
echo "0,1" > /sys/class/graphics/fb0/pan
echo "0,0" > /sys/class/graphics/fb0/pan

#get current resolution and fill the variables
geom=$(fbset | awk '/geometry/ {print $2, $3}')
set -- $geom
WIDTH=$1
HEIGHT=$2
export SCREEN_WIDTH="$WIDTH"
export SCREEN_HEIGHT="$HEIGHT"

if [ "$HEIGHT" -gt "$WIDTH" ]; then
    if [ "$HEIGHT" -eq "854" ]; then
	export SDL_VIDEO_FBCON_ROTATION=CCW
 	sed -i 's/video_rotation[[:space:]]*=[[:space:]]*"[0-3]"/video_rotation = "3"/' "/mnt/card/cfw/retroarch/retroarch.cfg"
    else
	export SDL_VIDEO_FBCON_ROTATION=CW
        sed -i 's/video_rotation[[:space:]]*=[[:space:]]*"[0-3]"/video_rotation = "1"/' "/mnt/card/cfw/retroarch/retroarch.cfg"
    fi
else
    unset SDL_VIDEO_FBCON_ROTATION
    sed -i 's/video_rotation[[:space:]]*=[[:space:]]*"[0-3]"/video_rotation = "0"/' "/mnt/card/cfw/retroarch/retroarch.cfg"
fi

simplermenu_plus &
sleep 5
power_volume_handler &
tinymix 15 40 &

#sync
#poweroff
