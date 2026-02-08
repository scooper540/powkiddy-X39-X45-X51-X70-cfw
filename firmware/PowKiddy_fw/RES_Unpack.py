from PIL import Image
from io import BufferedReader

import argparse
import os

import lib.image_codecs as image_codecs
from lib.Resources import RES_TYPES
from lib.utils import DataReader


parser = argparse.ArgumentParser(description='Actions PAD resource unpacker')
parser.add_argument('files', nargs='+', type=argparse.FileType('rb'), help="Files for unpack (.res or .str)")
args = parser.parse_args()

if len(args.files) == 0:
	print("No file specified")
	exit(1)

src_file: BufferedReader
for src_file in args.files:
	src_fullname = os.path.basename(src_file.name)
	src_dir = os.path.dirname(src_file.name)
	src_name, src_ext = os.path.splitext(src_fullname)
	src_ext = src_ext.lower()

	if not src_file or not src_file.readable:
		print(src_fullname, "is not readable!")
		exit(2)

	if src_ext not in ('.res', '.str'):
		continue

	if src_ext == '.str':
		# This is a string resource.
		loc_file = open(f"{src_dir}/{src_name}.txt", "wt", encoding='utf-8')
	else:
		loc_file = None
		dir = os.path.join(src_dir, src_fullname + "_DATA")
		os.makedirs(dir, exist_ok=True)

	# Read header info
	file = DataReader(src_file.name)
	f_type = file.read_string(3)
	res_version = file.read_int(1)
	items_count = file.read_int(2)
	unkn_byte_1 = file.read_int(2)  # 0x00c0 ... or 0xc000 (int)?
	# v2.0.00.230822.1430
	fv_ver_1 = file.read_int(1)  # 0
	fv_ver_2 = file.read_int(1)  # 2
	fv_ver_3 = file.read_int(1)  # 0
	fv_ver_4 = file.read_int(1)  # 0
	fv_ver_5 = file.read_int(1)  # 0  Maybe 4 bytes CRC? But always zero...
	fv_ver_6 = file.read_int(1)  # 0
	fv_ver_7 = file.read_int(1)  # 0
	fv_ver_8 = file.read_int(1)  # 0

	print(f'## {src_fullname}: {items_count} item(s):')
	print('  | FILE    | OFFSET   | SIZE | RESOURCE TYPE')
	#     ' - 123456789 1234567890 123456 12345678901234567890123456789012'
	if f_type == 'RES':
		last_pos = file.get_pos()
		resources = {}
		for i in range(items_count):
			file.set_pos(last_pos)
			#  40 03 00 00 f3 00 08 50 49 43 31 00 00 00 00 00
			# |  << 832   | 243 | 8| P  I  C  1               |
			# |FILE OFFSET|SIZE |RT|         File name        |
			data_offset = file.read_int(4)
			data_lenght = file.read_int(2)
			res_type = file.read_int(1)
			file_name = file.read_string(9)
			last_pos = file.get_pos()  # Save current position for next header record

			print(f' - {file_name: <9} {data_offset: <10} {data_lenght: <6} {RES_TYPES[res_type]: <32}')

			# Go to file position
			file.set_pos(data_offset)

			if res_type in (3, 4):
				if loc_file:
					#loc_file.write(f"{file_name}[{RES_TYPES[res_type]}]: {file.read_string(data_lenght)}\n")
					string = file.read_string(data_lenght).replace('\n', '\\n').replace('\r', '\\r')
					loc_file.write(f"{file_name}={string}\n")
				else:
					# Text string
					with open(f"{dir}/{file_name}.{RES_TYPES[res_type]}.txt", "wb") as out:
						out.write(file.read_bytes(data_lenght - 1))  # End byte is null

			elif res_type == 5:
				# Image
				width = file.read_int(2)
				height = file.read_int(2)
				size = width * height * 3
				# if size > data_lenght:
				#	size = data_lenght - 4
				img = Image.frombytes("RGBA", (width, height), file.read_bytes(size), image_codecs.RES_PNG)
				img.save(f"{dir}/{file_name}.{RES_TYPES[res_type]}.png")

			elif res_type in (7, 8):
				# Animation/compressed image
				width = file.read_int(2)
				height = file.read_int(2)
				size = file.read_int(4)

				img = Image.frombytes(
					"RGB" if res_type == 7 else "RGBA",
					(width, height),
					file.read_bytes(size),
					image_codecs.RES_GZIP_PNG
				)

				img.save(f"{dir}/{file_name}.{RES_TYPES[res_type]}.png")

			elif res_type == 11:
				# Image, 32 bit, RGBA
				width = file.read_int(2)
				height = file.read_int(2)
				size = width * height * 4
				img = Image.frombytes("RGBA", (width, height), file.read_bytes(size))
				img.save(f"{dir}/{file_name}.{RES_TYPES[res_type]}.png")

			else:
				with open(f"{dir}/{file_name}.{RES_TYPES[res_type]}.bin", "wb") as out:
					out.write(file.read_bytes(data_lenght))

	if loc_file:
		loc_file.close()
