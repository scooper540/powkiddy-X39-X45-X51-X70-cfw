from lib.StaticVars import *
from lib.utils import DataReader, size_human
import os


FIRMWARE = 'firmware.fw'
OUTPUT = '_UNPACKED_FW'


if not os.path.exists(OUTPUT):
	os.mkdir(OUTPUT)


class FirmwareException(BaseException):
	pass


fw = DataReader(FIRMWARE)

magic = fw.read_string(16)
header_size = fw.read_int(4)
unknw_1 = fw.read_int(16)
items_count = fw.read_int(4)
unknw_2 = fw.read_int(24)

#print(f">> {fw.file_name} ({size_human(fw.file_size)}), {items_count} items:")
print(">> {} ({}), {} items:".format(fw.file_name, size_human(fw.file_size), items_count))

print('-' * 64)

if magic != FWU_MAGIC_WF:
	raise FirmwareException("Wrong magic string in file!")

items = []
for i in range(0, items_count):
	name = fw.read_string(16)
	filesystem = fw.read_string(8)
	offset = fw.read_int(8)
	size = fw.read_int(8)
	reserved = fw.read_bytes(24)
#	print(f"{(name + '.' + filesystem):<24} {offset:>12} {size:>12} ({size_human(size):>9})")
	print("{:<24} {:>12} {:>12} ({:>9})".format(name + '.' + filesystem, offset, size, size_human(size)))
	items.append((name, filesystem, offset, size))

if fw.get_pos() != header_size:
	raise FirmwareException("Wrong header size!")

print('-' * 64)

for item in items:
	name, fs, offset, size = item
	print("Unpacking {:<16}".format(name), end=" ")

	# Go to file start position
	fw.set_pos(offset)

	try:
		with open(os.path.join(OUTPUT, "{}.{}.bin".format(name, fs)), "wb") as f:
			f.write(fw.read_bytes(size))
	except FirmwareException as e:
		print('ERROR', e)
	else:
		print('[DONE]')
