from PIL import Image, ImageFile
import zlib
import struct

RES_PNG = "RES_IMAGE"
RES_GZIP_PNG = "RES_GZIP_IMAGE"
RATIO = 8.2258


# Error codes:
#	-1: "image buffer overrun error",
#	-2: "decoding error",
#	-3: "unknown error",
#	-8: "bad configuration",
#	-9: "out of memory error",


class ImageDecoder(ImageFile.PyDecoder):
	def decode(self, buffer: bytes):
		x = 0
		y = 0

		if self.im.mode == 'RGB':
			bpp = 2
		else:
			bpp = 3

		# Two bytes per pixel / RGB_565
		for i in range(0, len(buffer), bpp):
			pix = struct.unpack('<H', buffer[i:i + 2])[0]
			pix_r = int((pix >> 11 & 0x1F) * RATIO)
			pix_g = int((pix >> 6 & 0x1F) * RATIO)
			pix_b = int((pix & 0x1F) * RATIO)

			if bpp == 2:
				self.im.putpixel((x, y), (pix_r, pix_g, pix_b))  # RGB
			else:
				self.im.putpixel((x, y), (pix_r, pix_g, pix_b, buffer[i + 2]))  # RGBA

			# Calculate next pixel
			x += 1
			if x >= self.im.size[0]:
				y += 1
				x = 0

		return -1, 0


class ImageEncoder(ImageFile.PyEncoder):
	def encode(self, bufsize: int):
		if self.im.mode == 'RGB':
			buffer = b'\x00' * self.im.size[0] * self.im.size[1] * 2  # 16-bit RGB_565
		else:
			buffer = b'\x00' * self.im.size[0] * self.im.size[1] * 3  # 16-bit RGB_565 + 8bit alpha mask

		for y in range(0, self.im.size[1]):
			for x in range(0, self.im.size[0]):
				pixel = self.im.getpixel((x, y))  # returns (R, G, B) or (R, G, B, A)

				r = pixel[0] / RATIO
				g = pixel[1] / RATIO
				b = pixel[2] / RATIO

				buffer += ((r & 0x1F) << 11 | (g & 0x1F) << 6 | (b & 0x1F) << 0)

				if self.im.mode == 'RGBA':
					# RGBA - append alpha channel
					buffer += pixel[3]

		# (bytes_encoded, errcode, bytes)
		return len(buffer), 0, zlib.compress(buffer)


class CompressedImageEncoder(ImageFile.PyEncoder):
	def encode(self, bufsize: int):
		bytes_encoded, errcode, buffer = super().encode(bufsize)
		return bytes_encoded, errcode, zlib.compress(buffer)


class CompressedImageDecoder(ImageDecoder):
	def decode(self, buffer: bytes):
		return super().decode(zlib.decompress(buffer))


Image.register_decoder(RES_PNG, ImageDecoder)
Image.register_encoder(RES_PNG, ImageEncoder)
Image.register_decoder(RES_GZIP_PNG, CompressedImageDecoder)
Image.register_encoder(RES_GZIP_PNG, CompressedImageEncoder)
