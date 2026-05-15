#/bin/sh
cd /mnt/card/cfw/resources
mkdir nandp1
mount /dev/nand0p1 nandp1
cp boot_logo-original-${SCREEN_WIDTH}x${SCREEN_HEIGHT}.bmp.gz nandp1/boot_logo.bmp.gz
umount nandp1
rm -rf nandp1

