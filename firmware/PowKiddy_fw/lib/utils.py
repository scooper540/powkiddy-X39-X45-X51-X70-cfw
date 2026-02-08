import os
import io
from math import floor


def print_hex(data, columns: int = 16):
	col = 0
	for b in data:
		print("%02x" % b, end=" ")
		col += 1
		if col == columns:
			col = 0
			print("")
	print("")


def calc_checksum(data: bytes):
	result = 0
	for pos in range(0, len(data) >> 2):
		result += int.from_bytes(data[pos * 4: pos * 4 + 4], 'little', signed=False)
	return (result & 0xFFFFFFFF).to_bytes(4, 'little', signed=False)


def cfg_hash(data1: bytes, data2: bytes):
	result = 0
	for i in range(len(data2)):
		result = result * 0x1000193 ^ data2[i]


def size_human(size: int, limit: int = 2):
	sz = ' KMGTP'
	factor = floor((len(str(size)) - 1) / 3)
	fmt_str = "%." + str(limit) + "f"
	fmt_str = fmt_str % (size / pow(1024, factor))
	return '{} {}B'.format(fmt_str, sz[factor])


class BytesReader(io.BytesIO):
	def __init__(self, initial_bytes=..., order: str = 'little'):
		super().__init__(initial_bytes)
		self.int_byteorder = order

	def read_int(self, size: int, signed: bool = False):
		return int.from_bytes(self.read(size), self.int_byteorder, signed=signed)

	def read_string(self, size: int, codepage: str = 'utf-8'):
		return self.read(size).decode(codepage).strip('\x00')

	def __len__(self):
		return self.getbuffer().nbytes


class DataReader:
	def __init__(self, file_name: str, order: str = 'little') -> None:
		self._file = open(file_name, 'rb')
		self.file_name = os.path.basename(self._file.name)
		self.file_path = os.path.dirname(self._file.name)
		self._file.seek(0, os.SEEK_END)  # Got to end of file
		self.file_size = self._file.tell()
		self._file.seek(0)  # Go to start of file
		self._int_byteorder = order

	def get_pos(self):
		return self._file.tell()

	def set_pos(self, pos: int):
		self._file.seek(pos, os.SEEK_SET)  # From start

	def read_from(self, pos: int, size: int):
		p_old = self._file.tell()
		self._file.seek(pos)
		data = self._file.read(size)
		self._file.seek(p_old)  # Return back

	def byteorder_is_big(self, flag: bool):
		self._int_byteorder = 'big' if flag else 'little'

	def __del__(self):
		self._file.close()

	def read_int(self, size: int, signed: bool = False):
		return int.from_bytes(self._file.read(size), self._int_byteorder, signed=signed)

	def read_bytes(self, size: int):
		return self._file.read(size)

	def read_string(self, size: int, codepage: str = 'utf-8'):
		return self._file.read(size).decode(codepage).strip('\x00')
