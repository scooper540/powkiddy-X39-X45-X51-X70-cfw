#!/bin/sh

usb_gandroid0_enable="/sys/class/android_usb/android0/enable"
usb_gandroid0_idVendor="/sys/class/android_usb/android0/idVendor"
usb_gandroid0_idProduct="/sys/class/android_usb/android0/idProduct"
usb_gandroid0_functions="/sys/class/android_usb/android0/functions"
usb_gandroid0_lun0="/sys/class/android_usb/android0/f_mass_storage/lun0/file"
usb_gandroid0_lun1="/sys/class/android_usb/android0/f_mass_storage/lun1/file"
usb_gandroid0_iManufacturer="/sys/class/android_usb/android0/iManufacturer"
usb_gandroid0_iProduct="/sys/class/android_usb/android0/iProduct"

echo "------usbmond start------"

insmod /lib/modules/3.10.0/libcomposite.ko
insmod /lib/modules/3.10.0/g_android.ko

echo "Actions" > $usb_gandroid0_iManufacturer
echo "LS360F" > $usb_gandroid0_iProduct
echo '0' > $usb_gandroid0_enable
echo "10d6" > $usb_gandroid0_idVendor
echo "0c01" > $usb_gandroid0_idProduct
echo "adb" > $usb_gandroid0_functions
echo '1' > $usb_gandroid0_enable

# start adbd
adbd&
