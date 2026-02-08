from ctypes import *
import sqlite3
import os


FW_FILE_PATH = "firmware.bin"

TMP_DB_NAME = "firmware_db.sqlite"
TMP_DIR = "powkiddy_FWU"
BUFFER_SIZE = 128 * 1024 * 1024

DLL_SCRIPT = CDLL("DLLs/Script.dll")
# DLL_PRODUCT = CDLL("DLLs/Production.dll")

# print("Py_GetScript", mylib.Py_GetScript(FW_FILE_PATH.encode('ascii')))
# uncompyle6.exe -o . Common.pyo
# uncompyle6.exe -o . CommonEx.pyo
# mv Common.pyo_dis Common.py
# mv CommonEx.pyo_dis CommonEx.py
# 2to3 -w Common.py
# 2to3 -w CommonEx.py

# Nothing happens :( Seems like this only for original app
# error = "This just a test message"
# product_tid = DLL_PRODUCT.StartupDbg(FW_FILE_PATH.encode('ascii'))
# DLL_PRODUCT.Py_ShowMessage(2, product_tid, error, len(error))


fw_path_bytes = FW_FILE_PATH.encode('ascii')
fsize = DLL_SCRIPT.Py_OpenFirmware(fw_path_bytes, 0, 0)
if fsize == 0:
	raise Exception("Can't open firmware file!")

print("Firmware :", FW_FILE_PATH, fsize, "bytes")

buf_db = c_buffer(b'\x00', fsize + 1024)
buf_img = c_buffer(b'\x00', 520)
fsize = DLL_SCRIPT.Py_OpenFirmware(fw_path_bytes, buf_db, buf_img)

image_path = buf_img.value.decode('ascii')
print("Image.img:", image_path, fsize, "bytes")

db_size = 0
with open(TMP_DB_NAME, "wb") as f:
	f.write(buf_db)
	db_size = f.tell()
print("SQLite DB:", TMP_DB_NAME)


if not os.path.exists(TMP_DIR):
	os.mkdir(TMP_DIR)

buffer = (c_byte * BUFFER_SIZE)()

# Unpack all files from firmware
with sqlite3.connect(TMP_DB_NAME) as db:
	c = db.cursor()

	with open('dump.sql', 'wt') as sql:
		for line in db.iterdump():
			sql.write(line + "\n")

	c.execute('SELECT Keyword, FileName, FileLength, File FROM FileTable;')
	print("Files in database:")
	for row in c.fetchall():
		# size = size + (int(i[0]) + align) / align * align
		# print(row)
		# print(f"{row[1]:>16} {row[2]:>9} {row[0]:>16} {row[3]}")

		readed = DLL_SCRIPT.Py_ReadFileInFW(buf_img.value, row[1].encode('utf-8'), 0, len(buffer), buffer, 512)
		print(row[1], row[2], readed)

		# Note: All texts in GBK encoding! (Simplified chinese)
		with open(os.path.join(TMP_DIR, row[1]), 'wb') as f:
			f.write(buffer)
			f.truncate(row[2])


# Remove temporary folder "C:\\ProgramData\\Actions Production Tool\\"
# os.remove(os.path.abspath(os.path.join(image_path, os.pardir)))
