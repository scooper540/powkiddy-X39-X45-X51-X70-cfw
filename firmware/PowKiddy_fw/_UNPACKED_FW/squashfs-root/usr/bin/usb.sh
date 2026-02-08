#!/bin/sh

usb_gandroid0_enable="/sys/class/android_usb/android0/enable"
usb_gandroid0_idVendor="/sys/class/android_usb/android0/idVendor"
usb_gandroid0_idProduct="/sys/class/android_usb/android0/idProduct"
usb_gandroid0_functions="/sys/class/android_usb/android0/functions"
usb_gandroid0_lun0="/sys/class/android_usb/android0/f_mass_storage/lun0/file"
usb_gandroid0_lun1="/sys/class/android_usb/android0/f_mass_storage/lun1/file"
usb_gandroid0_iManufacturer="/sys/class/android_usb/android0/iManufacturer"
usb_gandroid0_iProduct="/sys/class/android_usb/android0/iProduct"

disable_usb() {
    if [ -f /sys/class/android_usb/android0/enable ]; then
        killall -9 adbd
        rmmod g_android
        rmmod libcomposite
        #echo b > /proc/acts_udc
    fi
        echo b > /proc/acts_udc
}

enable_usb_host() {
	disable_usb
    echo a > /proc/acts_hcd
}

disable_usb_host() {
    echo b > /proc/acts_hcd
}

if [ $1 = ADD_FUNCTIONS ];then
    echo "------ $1: $2 [$3]"
    nluns=$3
    if [ x$nluns = x"" ];then
        nluns=2
    fi
    if [ ! -f /sys/class/android_usb/android0/enable ]; then
        echo a > /proc/acts_udc
        insmod /lib/modules/3.10.0/libcomposite.ko
        insmod /lib/modules/3.10.0/g_android.ko nluns=$nluns
        if [ ! $2 = mass ];then
            adbd&
        fi
    fi

    enabled=`cat /sys/class/android_usb/android0/enable`
    functions=`cat /sys/class/android_usb/android0/functions`
    func=$2

    if [ x$functions = x"mass_storage,adb" -a ! $func = "mass_adb"  ];then
        func="mass_adb"
    fi

	if [ $func = "mass" ];then
		echo '0' > $usb_gandroid0_enable
		echo "10d6" > $usb_gandroid0_idVendor
		echo "fffe" > $usb_gandroid0_idProduct
		echo "mass_storage" > $usb_gandroid0_functions
        if [ x$nluns = x"1" ]; then
            echo "" > $usb_gandroid0_lun0
        else
            echo "" > $usb_gandroid0_lun0
            echo "" > $usb_gandroid0_lun1
        fi
		echo '1' > $usb_gandroid0_enable
	elif [ $func = "adb" ];then
		echo '0' > $usb_gandroid0_enable
		echo "10d6" > $usb_gandroid0_idVendor
		echo "0c01" > $usb_gandroid0_idProduct
		echo "adb" > $usb_gandroid0_functions
		echo '1' > $usb_gandroid0_enable
	elif [ $func = "mass_adb" ];then
		echo '0' > $usb_gandroid0_enable
		echo "10d6" > $usb_gandroid0_idVendor
		echo "0c02" > $usb_gandroid0_idProduct
		echo "mass_storage,adb" > $usb_gandroid0_functions
        if [ x$nluns = x"1" ]; then
            echo "" > $usb_gandroid0_lun0
        else
            echo "" > $usb_gandroid0_lun0
            echo "" > $usb_gandroid0_lun1
        fi
		echo '1' > $usb_gandroid0_enable
	fi
fi

if [ $1 = ADD_LUN ];then
	echo "------ $1: $2 $3 [$4]"
	if [ x$4 = x"1" ]; then
        if [ $2 = LUN0 ];then
            echo $3 > $usb_gandroid0_lun0
        fi
    else
        if [ $2 = LUN0 ];then
            echo $3 > $usb_gandroid0_lun0
        elif [ $2 = LUN1 ];then
            echo $3 > $usb_gandroid0_lun1
        fi
    fi
fi

if [ $1 = REMOVE_LUN ];then
	echo "------ $1: $2 [$3]"
    if [ x$3 = x"1" ]; then
        if [ $2 = LUN0 -a -f $usb_gandroid0_lun0 ];then
            echo "" > $usb_gandroid0_lun0
        fi
    else
        if [ $2 = LUN0 -a -f $usb_gandroid0_lun0 ];then
            echo "" > $usb_gandroid0_lun0
        elif [ $2 = LUN1 -a -f $usb_gandroid0_lun1 ];then
            echo "" > $usb_gandroid0_lun1
        fi
    fi
fi

if [ $1 = DISABLE ];then
    echo "---- DISABLE ----"
    disable_usb
fi

if [ $1 = ENABLE_HOST ];then
    echo "---- ENABLE_HOST ----"
    enable_usb_host
fi

if [ $1 = DISABLE_HOST ];then
    echo "---- DISABLE_HOST ----"
    disable_usb_host
fi
