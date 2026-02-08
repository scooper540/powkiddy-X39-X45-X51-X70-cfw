#!/usr/bin/env python

import argparse
import struct
import sys
import os
from io import BufferedReader
from datetime import datetime
from lib.utils import calc_checksum

BLOCK_SIZE = 512
CHUNK_SIZE = 1024 * 1024  # Must be multiple by 4!

parser = argparse.ArgumentParser(description='PowKiddy firmware packer')
parser.add_argument('-uboot', help="RAW.1.uboot.bin", type=argparse.FileType('rb'), required=True)
parser.add_argument('-misc', help="0.misc.img", type=argparse.FileType('rb'), required=True)
parser.add_argument('-recovery', help="1.recovery.img", type=argparse.FileType('rb'), required=True)
parser.add_argument('-system', help="3.system.img", type=argparse.FileType('rb'), required=True)
parser.add_argument('-res', help="5.res.img", type=argparse.FileType('rb'), required=True)
parser.add_argument('-ver', help="Custom firmware version", type=str, default='2.0.00')
args = parser.parse_args()

file_uboot: BufferedReader = args.uboot
file_misc: BufferedReader = args.misc
file_rec: BufferedReader = args.recovery
file_sys: BufferedReader = args.system
file_res: BufferedReader = args.res
fw_ver: str = args.ver

dt_now = datetime.now()
dt_date = dt_now.strftime('%y%m%d')  # year-month-day
dt_time = dt_now.strftime('%H%M')    # hour-minute

FILES = (
	(file_uboot, 'uboot.bin', 1, 1),
	(file_misc, 'misc.img', 0, 0),
	(file_rec, 'recovery.img', 0, 1),
	(file_sys, 'system.img', 0, 3),
	(file_res, 'res.img', 0, 5),
)

print(f'# Creating firmware v{fw_ver}.{dt_date}.{dt_time}...')
print('  FILE NAME                             SIZE   CRC   ')
#     '> uboot.bin                           647680 B4CEC38C'

with open('update.zip', 'wb') as fw:
	header = struct.pack("<4s56sL", 'PATO'.encode('ASCII'), f'{fw_ver}.{dt_date}.{dt_time}'.encode('ASCII'), len(FILES))

	offset = 2048
	fw.write(b'\x00' * offset)  # Write temporary (empty) header

	for record in FILES:
		fd, name, flag, part = record

		crc = 0
		data = fd.read(4)
		while data:
			crc += int.from_bytes(data, 'little', signed=False)
			fw.write(data)
			data = fd.read(4)

		size = fd.tell()
		crc = (crc & 0xFFFFFFFF).to_bytes(4, 'little', signed=False)

		size_b = int(size / BLOCK_SIZE)
		offset_b = int(offset / BLOCK_SIZE)

		if size < BLOCK_SIZE:
			print(f"Error on \"{os.path.basename(fd.name)}\": File can't be less than {BLOCK_SIZE} bytes ({size})")
			exit(1)

		if size % BLOCK_SIZE != 0:
			print(f"Error on \"{os.path.basename(fd.name)}\": File size must be a multiple of {BLOCK_SIZE} ({size})")
			exit(1)

		print(f'> {name: <32} {size: >9} {crc.hex()}')
		header += struct.pack("<32sBBxxLL4s16s", name.encode('ASCII'), flag, part, size_b, offset_b, crc, b'\x00')
		offset += size  # Calculate next offset

	header += b'\x00' * (2044 - len(header))  # Padding to 2044 bytes
	header += calc_checksum(header)    # Append last 4 bytes of CRC
	fw.seek(0)
	fw.write(header)  # Write header into file
