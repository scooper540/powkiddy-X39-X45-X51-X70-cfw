#!/bin/bash
./FW_Create.py \
	-uboot update.zip_DATA/RAW.1.uboot.bin \
	-misc update.zip_DATA/0.misc.img \
	-recovery update.zip_DATA/1.recovery.img \
	-system update.zip_DATA/3.system.img \
	-res update.zip_DATA/5.res.img
