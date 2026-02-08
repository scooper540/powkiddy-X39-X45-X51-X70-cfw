import argparse
import os

from lib.utils import DataReader

# TODO: Convert to XML ?

# ActionsSDK/libsrc/style/style.c
# ActionsSDK/include/style.h
# define RESOURCE_PICREGION 1
# define RESOURCE_STRING 2
# define RESOURCE_RESGROUP 3
# define RESOURCE_PICTURE 4

SCENE_RES_TYPE = ('UNKNOWN', 'PIC_REGION', 'STRING', 'RES_GROUP', 'PICTURE')


def read_resource(file: DataReader, level=1):
	res_start = file.get_pos()
	res_type = file.read_int(1)
	res_id = file.read_int(4)
	res_size = file.read_int(4)

	print("\t" * level + f"{SCENE_RES_TYPE[res_type]:<12} {hex(res_id)[2:]}", end=" ")

	# SCENE_RES_TYPE = ('UNKNOWN', 'PIC_REGION', 'STRING', 'RES_GROUP', 'PICTURE')

	level += 1
	if res_type == 1:
		# PIC_REGION
		pic_region_start = file.get_pos()
		x = file.read_int(2)
		y = file.read_int(2)
		w = file.read_int(2)
		h = file.read_int(2)
		visible = file.read_int(1)
		frames_cnt = file.read_int(2)
		pic_offset = file.read_int(4)
		# Read frames
		file.set_pos(pic_region_start + pic_offset)
		frames = [file.read_int(2) for i in range(frames_cnt)]
		# Print info
		print(f"{w}x{h} at {x}:{y}, {'visible' if visible else 'hidden'}, {frames}")

	elif res_type == 2:
		# STRING
		x = file.read_int(2)
		y = file.read_int(2)
		w = file.read_int(2)
		h = file.read_int(2)
		fg = file.read_int(4)
		bg = file.read_int(4)
		visible = file.read_int(1)
		text_align = file.read_int(1)
		text_mode = file.read_int(1)
		text_height = file.read_int(1)
		str_id = file.read_int(2)
		text_scroll = file.read_int(1)
		text_direction = file.read_int(1)
		text_space = file.read_int(2)
		text_pixel = file.read_int(2)
		print(f"#{str_id}: {w}x{h} at {x}:{y}, [{text_align} {text_mode} {text_height}px]"
                    + f", [{text_scroll} {text_direction} {text_space} {text_pixel}]"
                    + f", {'visible' if visible else 'hidden'}")

	elif res_type == 3:
		# RES_GROUP
		abs_x = file.read_int(2)
		abs_y = file.read_int(2)
		x = file.read_int(2)
		y = file.read_int(2)
		w = file.read_int(2)
		h = file.read_int(2)
		bg_r = file.read_int(1)  # RGBA code
		bg_g = file.read_int(1)
		bg_b = file.read_int(1)
		bg_a = file.read_int(1)
		is_visible = file.read_int(1)
		opaque = file.read_int(1)
		transparence = file.read_int(2)
		resource_sum = file.read_int(4)
		child_offset = file.read_int(4)
		print(f"{w}x{h} at {x}x{y} ({abs_x}x{abs_y}). [{bg_r}, {bg_g}, {bg_b}, {bg_a}], {resource_sum} items:")

		next_res = file.get_pos()
		for i in range(resource_sum):
			file.set_pos(next_res)
			next_res = read_resource(file, level)

	elif res_type == 4:
		# PICTURE
		x = file.read_int(2)
		y = file.read_int(2)
		w = file.read_int(2)
		h = file.read_int(2)
		visible = file.read_int(1)
		pic_id = file.read_int(2)
		print(f"#{pic_id}: {w}x{h} at {x}:{y}, {'visible' if visible else 'hidden'}")

	else:
		raise Exception(f"Unknown resource type \"{res_type}\" at {res_start}!")

	return res_start + res_size


parser = argparse.ArgumentParser(description='Actions PAD resource unpacker')
parser.add_argument('file', type=argparse.FileType('rb'), help="Files for unpack (.res or .str)")
args = parser.parse_args()

file = DataReader(args.file.name)

# Header
magic = file.read_int(4)
scenes_count = file.read_int(4)
reserve_1 = file.read_bytes(8)

if magic != 0x18:
	print("Not a style file!")
	exit(1)

next_scene = file.get_pos()
for i in range(scenes_count):
	file.set_pos(next_scene)
	scene_id = file.read_int(4)
	offset = file.read_int(4)
	size = file.read_int(4)
	next_scene = file.get_pos()

	# Read scene
	file.set_pos(offset)
	x = file.read_int(2)
	y = file.read_int(2)
	w = file.read_int(2)
	h = file.read_int(2)
	bg_r = file.read_int(1)  # RGBA code
	bg_g = file.read_int(1)
	bg_b = file.read_int(1)
	bg_a = file.read_int(1)
	is_visible = file.read_int(1)
	opaque = file.read_int(1)
	transparence = file.read_int(2)
	resource_sum = file.read_int(4)
	child_offset = file.read_int(4)
	direction = file.read_int(1)
	keys = [file.read_int(1) for i in range(16)]  # 16 key codes

	print(f"Scene {hex(scene_id)[2:]}: {w}x{h} on {x}x{y}, [{bg_r}, {bg_g}, {bg_b}, {bg_a}]"
            + f" {transparence} {is_visible} {opaque} {direction}")
	print("Scene keys:", keys)

	# Read resource in scene
	next_res = offset + child_offset  # From scene position
	for res in range(resource_sum):
		file.set_pos(next_res)
		next_res = read_resource(file)
