from .StaticVars import *
from .utils import DataReader, print_hex


class FWDecoderException(BaseException):
	pass


class FWDecoder(DataReader):
	def __init__(self, buf: DataReader, fw_offset: int) -> None:
		self._file = buf._file
		# Problem: When read from file outside this class - reader position can be changed with uexpected result!
		self._file.seek(fw_offset)
		self.fw_offset = fw_offset

	def decode_keys(self):
		# print("FW size/block:", size_fw, size_blk)
		sf_sig_A = self.read_bytes(16)
		size_fw = self.read_int(4)
		size_blk = self.read_int(4)
		version = self.read_bytes(2)
		sf_sig_B = self.read_bytes(16)

		crypt_head = self.read_bytes(16)
		crypt_ver = self.read_int(1)
		crypt_key = self.read_bytes(32)

		if sf_sig_A != FWU_MAGIC_SIG_A:
			raise FWDecoderException("Wrong SF signature A!", sf_sig_A)
		if sf_sig_B != FWU_MAGIC_SIG_B:
			raise FWDecoderException("Wrong SF signature B!", sf_sig_B)
		if version != b'\x7E\xE1':  # 0x0DD0 = v1, 0x0ED0 = v2, 0x7EE1 = v3
			raise FWDecoderException("Unsupported SF version!", version.hex())
		if crypt_ver != 3:
			raise FWDecoderException("Unsupported crypt version!", crypt_ver)

		# Debug
		#print(f"{size_fw} bytes. Version: 0x{version.hex().upper()}", end=" ")

		self.set_pos(self.fw_offset + 494)
		ba = self.read_int(1) & 0xF
		self.set_pos(self.fw_offset + 510)
		bb = self.read_int(1) & 0xF
		block_a_pos = size_blk * (ba + 2)
		block_b_pos = size_blk * (ba + bb + 5)

		#print(block_a_pos, block_b_pos)

		self.set_pos(self.fw_offset + block_a_pos)
		self.block_a = self._decode_block_a(list(self.read_bytes(1024)))

		self.set_pos(self.fw_offset + block_b_pos)
		self.block_b = self._decode_block_b(list(self.read_bytes(512)))

		self._decode_crypto()

	def calc_crc(self, data: list, size: int):
		# Check block CRC
		crc = [0x00] * 20

		for i in range(0, size):
			crc[i % 20] ^= data[i]

		for i in range(0, 20):
			crc[i] = 0xFF - crc[i]  # Emulate "~" (bitwise NOT) operator from C++

		return crc

	def _decode_block_a(self, data: list):
		# Decode block A
		p = 32 * (data[1002] & 0x1F)
		key = [0x00] * 32
		for i in range(0, 20):
			data[1004 + i] ^= BLK_A[p + i]
			key[i] = data[1004 + i]
		for i in range(20, 32):
			key[i] = key[i - 20]
		for i in range(0, 992):
			data[4 + i] ^= key[i % 32] ^ BLK_A[i]

		crc = self.calc_crc(data[3:], 1001)

		if list(data[1024 - 20:]) != crc:
			raise FWDecoderException('Block A CRC check FAILED!')
		else:
			print("[CRC_A: OK]", end=" ")

		return data

	def _decode_block_b(self, data: list):
		# Decode block B
		block_b_key = [0x00] * 20
		sb = self.block_a[4:]

		for i in range(0, 20):
			v = data[3 + 489 + i] ^ BLK_B[i]
			block_b_key[i] = v
			data[3 + 489 + i] = v ^ sb[i % 16]

		#                       (      block + 3, g_subblock_A + 4,         489)
		#                       (   uint8_t *buf,  uint8_t key[16], size_t size)

		#                       (        g_key_B,          20,          buf,        size,          g_perm_B)
		# decode_block_with_perm(uint8_t *keybuf, int keysize, uint8_t *buf, int bufsize, uint8_t perm[258])
		# -> compute_perm(keybuf, keysize, perm)
		# -> decode_perm(buf, bufsize, perm)

		# Compute perm
		perm = [0x00] * 258
		for i in range(0, 256):
			perm[i] = i
		idx = 0
		for i in range(0, 256):
			v = perm[i]
			idx = (v + block_b_key[i % 20] + idx) % 256
			perm[i] = perm[idx]
			perm[idx] = v

		# Decode perm
		idxa = perm[256]
		idxb = perm[257]
		for i in range(0, 489):
			idxa = (idxa + 1) % 256
			v = perm[idxa]
			idxb = (idxb + v) % 256
			perm[idxa] = perm[idxb]
			perm[idxb] = v
			data[3 + i] ^= perm[(v + perm[idxa]) % 256]

		if int.from_bytes(bytes(data[3:3 + 2]), 'little', signed=False) != 1:
			raise FWDecoderException("Block B perm decode FAILED!")

		# check_block(block, block + 492, 492)
		crc = self.calc_crc(data, 492)

		# print("")
		# print_hex(crc)
		# print_hex(data[492:])
		# print_hex(perm)
		# print_hex(data)

		if list(data[512 - 20:]) != crc:
			raise FWDecoderException('Block B CRC check FAILED!')
		else:
			print("[CRC_B: OK]", end=" ")

		return data

	def set_bit(self, bit_pos, data):
		data[int(bit_pos / 32)] |= 1 << (bit_pos % 32)

	def _decode_crypto(self):
		# Collect crypto information
		subblock = self.block_a[0:296]  # 0x128
		if (subblock[276] == 2):
			bits_a = 233
		elif (subblock[276] == 3):
			bits_a = 163
		else:
			raise FWDecoderException("Block A INFO check FAILED!")

		if int.from_bytes(bytes(subblock[286:286 + 2]), 'little', signed=False) != 1:
			raise FWDecoderException("Block A WORD check FAILED!")

		# Decode block A info
		info_a = {}
		info_a["bytes"] = int(bits_a / 8 + (bits_a % 8 != 0))
		info_a["words"] = 2 * info_a["bytes"]
		info_a["dwords"] = int(bits_a / 32 + (bits_a % 32 != 0))
		info_a["size"] = 4 * info_a["dwords"]
		self.info_a = info_a
		# 'bytes':  30
		# 'words':  60
		# 'dwords':  8
		# 'size':   32

		tmp = 2 * info_a["bytes"] + 38
		crypto_info_offset = 1004 - tmp + 5
		crypto_field_size = self.block_a[crypto_info_offset - 1]
		#crypto_info_buf_1 = [0x00] * info_a["size"]
		#crypto_info_buf_2 = [0x00] * info_a["size"]
		crypto_buf_1 = self.block_a[crypto_info_offset: crypto_info_offset + info_a["bytes"]]
		crypto_info_offset2 = crypto_info_offset + info_a["bytes"]
		crypto_buf_2 = self.block_a[crypto_info_offset2:crypto_info_offset2 + info_a["bytes"]]
		crypto_info_offset3 = int.from_bytes(self.block_b[13:13 + 2], 'little', signed=False) + 16
		crypto_buf_3 = self.block_b[crypto_info_offset3:crypto_info_offset3 + info_a["bytes"]]

		# ec_point_t ptrs = point(x, y) = 32-bit/4-bytes two coordinates
		self.set_pos(self.fw_offset + 91)
		point_x = self.read_int(info_a['bytes'])
		point_y = self.read_int(info_a['bytes'])

		field_poly = [0x00] * info_a["size"]
		if crypto_field_size == 4:
			self.set_bit(0, field_poly)
			self.set_bit(74, field_poly)
			self.set_bit(233, field_poly)
			field_bits = 233
			point_x = G_CRYPT_A
			point_y = G_CRYPT_B
			ec_a = G_CRYPT_KEY_2
			ptr7 = G_CRYPT_KEY_6
		elif crypto_field_size == 5:
			self.set_bit(0, field_poly)
			self.set_bit(3, field_poly)
			self.set_bit(6, field_poly)
			self.set_bit(7, field_poly)
			self.set_bit(163, field_poly)
			field_bits = 163
			point_x = G_CRYPT_KEY_3
			point_y = G_CRYPT_KEY_4
			ec_a = G_CRYPT_KEY_1
			ptr7 = G_CRYPT_KEY_5
		else:
			raise FWDecoderException("Unsupported crypto_info_byte!", crypto_field_size)

		# crypto4(crypto_hdr.key,            &ptrs, g_decode_buffer3);
		# crypto4(   uint8_t *a1, ec_point_t *ptrs,     uint32_t *a3)
		# ec_mult(         a3,              ptrs,    &ptrs_others);
		# ec_mult(uint32_t *n, ec_point_t *point, ec_point_t *res)
		pos = self.find_last_bit_set(crypto_buf_3, True)

	def find_last_bit_set(self, buf: list, flag: bool):
		# Find last bit, that set to 1 (From end) in [uint32_t *buf]
		i = self.info_a['dwords'] - 1 if flag else 2 * self.info_a['dwords'] - 1

		while i >= 0 and buf[i] == 0:
			i -= 1

		if i < 0:
			raise FWDecoderException("Can't find last bit in buffer!", buf)

		for j in reversed(range(0, 31)):
			if buf[i] & (1 << j):
				return 32 * i + j

		raise FWDecoderException("Unreachable last bit", buf)
