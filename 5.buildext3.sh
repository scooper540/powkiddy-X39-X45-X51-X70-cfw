#/bin/sh

rm -rf rootfs.ext3
rm -rf mnt
dd if=/dev/zero of=rootfs.ext3 bs=1M count=250
mkfs.ext3 rootfs.ext3
mkdir mnt
sudo mount -o loop rootfs.ext3 mnt
sudo cp -a output/* mnt/
sudo umount mnt
cp rootfs.ext3 output-sd
find output-sd -name ".gitkeep" -type f -delete
