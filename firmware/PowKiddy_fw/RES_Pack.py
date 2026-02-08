from PIL import Image

import argparse
import os

import lib.image_codecs as image_codecs
from lib.Resources import RES_TYPES
from lib.utils import DataReader


parser = argparse.ArgumentParser(description='Actions PAD resource packer')
parser.add_argument('res_type', type=str, choices=['res', 'str'], help="Resource type")
parser.add_argument('path', type=str, help="Directory with files or text file")
args = parser.parse_args()


if args.res_type == 'res':
	if not os.path.isdir(args.path):
		print(args.path, "is not a directory!")
		exit(1)

	print('Sorry, unsupported for now :(')
	exit(3)

if args.res_type == 'str':
	if not os.path.isfile(args.path):
		print(args.path, "is not a file!")
		exit(1)

	dst_name = os.path.splitext(args.path)
	if dst_name[1] != '.txt':
		print(args.path, "is not a text file!")
		exit(2)

	# Read strings
	strings = []
	with open(args.path, 'rt', encoding='utf-8') as src:
		for string in src.readlines():
			if string.startswith('STR'):
				str_num, str_text = string.split('=', 1)
				strings.append(str_text.replace('\\n', '\n').replace('\\r', '\r'))

	# Write strings
	with open(f"{dst_name[0]}.str", 'wb') as dst:
		dst.write("RES".encode('ascii'))  # Magic
		dst.write(b'\x19')
		dst.write(len(strings).to_bytes(2, 'little', signed=False))
		dst.write(b'\x00\xc0')
		dst.write(b'\x00\x02\x00\x00\x00\x00\x00\x00')

		next_offset = dst.tell()
		data_offset = dst.tell() + len(strings) * 16
		i = 0
		for string in strings:
			i += 1  # Start from one
			dst.seek(next_offset)
			bytes_string = string[:-1].encode('utf-8') + b'\x00'  # Replace end line to zero (C++ string end byte)
			dst.write(data_offset.to_bytes(4, 'little', signed=False))
			dst.write(len(bytes_string).to_bytes(2, 'little', signed=False))
			dst.write(b'\x03')  # 0x03 or 0x04 (utf-8 or unknown... maybe cp1251 or utf-16?)
			dst.write(f"STR{i:<6}".encode('utf-8').replace(b'\x20', b'\x00'))  # Replace spaces to null's
			next_offset = dst.tell()
			dst.seek(data_offset)
			dst.write(bytes_string)
			data_offset = dst.tell()
