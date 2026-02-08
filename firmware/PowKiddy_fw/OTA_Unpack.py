#!/usr/bin/env python

import argparse
import struct
import sys
import os
from io import BufferedReader
from lib.utils import calc_checksum

BLOCK_SIZE = 512
CHUNK_SIZE = 1024 * 1024  # Must be multiple by 4!


parser = argparse.ArgumentParser(description='PowKiddy firmware unpacker')
parser.add_argument('fw', nargs='?', type=argparse.FileType('rb'))
args = parser.parse_args()

src_file: BufferedReader = args.fw

src_name = os.path.basename(src_file.name)
src_dir = os.path.dirname(src_file.name)
dir = os.path.join(src_dir, src_name + "_DATA")
os.makedirs(dir, exist_ok=True)


# 64 bytes of package header (2048 bytes total. Last 4 bytes - CRC)
#
#  50 41 54 4f 32 2e 30 2e 30 30 2e 32 32 31 31 32 33 2e 30 32 30 34 00 00 00 00 00 00 00 00 00 00
# | P  A  T  O| 2  .  0  .  0  0  .  2  2  1  1  2  3  .  0  2  0  4                              |
#  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 05 00 00 00
#                                                                                     | 5 items   |


# Get file size
src_file.seek(0, os.SEEK_END)
fw_size = src_file.tell()

# Read header data
src_file.seek(0)
magic, fv_version, items_count = struct.unpack('<4s56sL', src_file.read(64))
fv_version = fv_version.decode().strip('\x00')  # Decode into regular string

src_file.seek(0)
header = src_file.read(2044)
header_crc = struct.unpack('<4s', src_file.read(4))[0]

crc = calc_checksum(header)
if crc != header_crc:
	print("Error: Wrong header CRC:", crc.hex(), "!=", header_crc.hex())
	exit(1)

#   	0	1	2	3	4	5	6	7	8	9	A	B	C	D	E	F
#  B	░	▒	▓	│	┤	╡	╢	╖	╕	╣	║	╗	╝	╜	╛	┐
#  C	└	┴	┬	├	─	┼	╞	╟	╚	╔	╩	╦	╠	═	╬	╧
#  D	╨	╤	╥	╙	╘	╒	╓	╫	╪	┘	┌	█	▄	▌	▐	▀

print('╔' + '═' * 73 + '╗')
print(f'║ File    : {os.path.basename(src_file.name): <61} ║')
print(f'║ Version : {fv_version:<32}' + ' ' * 30 + '║')
print(f'║ Size    :{fw_size:< 10}' + ' ' * 53 + '║')
print(f'║ CRC     : {header_crc.hex()}' + ' ' * 54 + '║')
print(f'║ Items   : {items_count: <2}' + ' ' * 60 + '║')
print('╚' + '═' * 73 + '╝')

print('╔═════════════════════════════════╤═════════╤═════════╤════╤════╤═════════╗')
print('║ FILE_NAME                       │    SIZE │  OFFSET │TYPE│PART│   CRC   ║')
print('╠═════════════════════════════════╧═════════╧═════════╧════╧════╧═════════╣')
#     '| uboot.bin                             2048      2048  RAW  1   11FEFF00 |'

next_offset = 64  # Header end, items info start
for i in range(items_count):
	# 64 bytes header of data partition
	#
	#  75 62 6f 6f 74 2e 62 69 6e 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	# | u  b  o  o  t  .  b  i  n                                                                     |
	#  01 01 00 00 f1 04 00 00 04 00 00 00 b4 ce c3 8c 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	# |FL|PN|-----|    SIZE   |  OFFSET   |   CRC32   |                   UNUSED                      |

	# NOTE: Size and Offset storead as sectors/blocks count, not bytes!

	src_file.seek(next_offset)
	file_name, flag, partition, size, offset, crc, sep = struct.unpack('<32sBBxxLL4s16s', src_file.read(64))
	next_offset += 64

	# Decode data
	file_name = file_name.decode().strip('\x00')
	offset = offset * BLOCK_SIZE
	size = size * BLOCK_SIZE

	p_type = "RAW" if flag else "IMG"
	print(f'║ {file_name: <32} {offset: >9} {size: >9}  {p_type}  {partition: <3} {crc.hex()} ║')

	if flag:
		f_num = f"RAW.{partition}"
	else:
		f_num = partition

	src_file.seek(offset)  # Go to begin of file
	crc_data = 0  # Start data CRC
	with open(f'{dir}/{f_num}.{file_name}', 'wb') as f:
		parts = int(size / CHUNK_SIZE)
		remain = size % CHUNK_SIZE

		for part in range(parts):
			data = src_file.read(CHUNK_SIZE)
			for pos in range(0, len(data) >> 2):
				crc_data += int.from_bytes(data[pos * 4: pos * 4 + 4], 'little', signed=False)
			f.write(data)

		data = src_file.read(remain)

		for pos in range(0, len(data) >> 2):
			crc_data += int.from_bytes(data[pos * 4: pos * 4 + 4], 'little', signed=False)
		f.write(data)

		crc_data = (crc_data & 0xFFFFFFFF).to_bytes(4, 'little', signed=False)
		if crc_data != crc:
			print("Error: Wrong CRC:", crc_data.hex())
			exit(1)

print('╚═════════════════════════════════════════════════════════════════════════╝')
