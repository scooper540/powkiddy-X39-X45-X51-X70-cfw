#!/bin/sh

SYSROOT="$(pwd)/sysroot"
OUT="$(pwd)/output/"
TARGET_TRIPLET="${TARGET_TRIPLET:-arm-linux-gnueabihf}"
STRIP_BIN="${STRIP_BIN:-arm-linux-gnueabihf-strip}"
READELF_BIN="${READELF_BIN:-arm-linux-gnueabihf-readelf}"

copy_tree_if_present() {
	src="$1"
	dst="$2"

	if [ -d "$src" ]; then
		mkdir -p "$dst"
		cp -a "$src"/. "$dst"/
	fi
}

copy_usr_share_except_alsa() {
	src="$1"
	dst="$2"

	if [ -d "$src" ]; then
		mkdir -p "$dst"
		find "$src" -mindepth 1 -maxdepth 1 ! -name alsa | while IFS= read -r path; do
			cp -a "$path" "$dst"/
		done
	fi
}

strip_arm_elf_files() {
	dir="$1"
	shift

	find "$dir" -type f | while IFS= read -r file; do
		if "$READELF_BIN" -h "$file" 2>/dev/null | grep -q "Machine:.*ARM"; then
			"$STRIP_BIN" "$@" "$file"
		fi
	done
}

mkdir -p $OUT/lib
mkdir -p $OUT/usr/lib
mkdir -p $OUT/proc
mkdir -p $OUT/tmp
mkdir -p $OUT/dev
mkdir -p $OUT/sys

copy_tree_if_present "$SYSROOT/lib" "$OUT/lib"
copy_tree_if_present "$SYSROOT/usr/$TARGET_TRIPLET/lib" "$OUT/lib"
copy_tree_if_present "$SYSROOT/usr/local/bin" "$OUT/usr/bin"
copy_tree_if_present "$SYSROOT/usr/local/lib" "$OUT/usr/lib"
copy_tree_if_present "$SYSROOT/usr/lib" "$OUT/usr/lib"
copy_usr_share_except_alsa "$SYSROOT/usr/share" "$OUT/usr/share"
echo "=== all files copied ==="
rm -rf output/lib/debug
rm -rf output/lib/gcc
rm -rf output/lib/ldscripts
rm -rf output/usr/include
rm -rf output/usr/lib/cmake
rm -rf output/usr/lib/pkgconfig

rm -rf output/lib/libasan*
rm -rf output/lib/libubsan*
rm -rf output/lib/libtsan*
rm -rf output/lib/liblsan*
rm -rf output/lib/libitm*
rm -rf output/lib/libcilkrts*
rm -rf output/lib/libstdc++.so.6.0.24-gdb.py
rm -rf output/lib/libmemusage.so
rm -rf output/lib/libpcprofile.so
rm -rf output/lib/libSegFault.so
rm -rf output/usr/lib/gconv

find $OUT -name "*.a" -type f -delete
find $OUT -name "*.la" -type f -delete

find $OUT -name ".gitkeep" -type f -delete
echo "=== cleaning done ==="
strip_arm_elf_files output/lib --strip-unneeded
strip_arm_elf_files output/usr/lib --strip-unneeded
strip_arm_elf_files output/usr/bin
echo "=== finished ==="
