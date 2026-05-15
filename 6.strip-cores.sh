#!/bin/sh
STRIP_BIN="${STRIP_BIN:-arm-linux-gnueabihf-strip}"
READELF_BIN="${READELF_BIN:-arm-linux-gnueabihf-readelf}"

strip_arm_elf_files() {
	dir="$1"
	shift

	find "$dir" -type f | while IFS= read -r file; do
		if "$READELF_BIN" -h "$file" 2>/dev/null | grep -q "Machine:.*ARM"; then
			"$STRIP_BIN" "$@" "$file"
		fi
	done
}

strip_arm_elf_files output-sd/cfw/lib --strip-unneeded
strip_arm_elf_files output-sd/cfw/retroarch/cores --strip-unneeded
