#!/bin/sh

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SYSROOT_DIR="${ROOT_DIR}/sysroot"
TARGET_TRIPLET="${TARGET_TRIPLET:-arm-linux-gnueabihf}"
TARGET_CPU="${TARGET_CPU:-cortex-a9}"
TARGET_FPU="${TARGET_FPU:-neon}"
TARGET_FLOAT_ABI="${TARGET_FLOAT_ABI:-hard}"
GCC_CROSS_DIR="/usr/lib/gcc-cross/${TARGET_TRIPLET}"
GCC_VERSION_DIR=""

copy_tree() {
	src="$1"
	dst="$2"

	if [ -d "$src" ]; then
		mkdir -p "$dst"
		cp -a "$src"/. "$dst"/
	fi
}

copy_file() {
	src="$1"
	dst="$2"

	if [ -e "$src" ]; then
		mkdir -p "$(dirname "$dst")"
		cp -a "$src" "$dst"
	fi
}

copy_matches() {
	src_dir="$1"
	dst_dir="$2"
	pattern="$3"

	if [ -d "$src_dir" ]; then
		for src in "$src_dir"/$pattern; do
			if [ -e "$src" ]; then
				copy_file "$src" "$dst_dir/$(basename "$src")"
			fi
		done
	fi
}

git submodule init
git submodule update

sudo apt-get -y update
sudo apt-get -y install \
	autoconf \
	automake \
	bc \
	binutils-arm-linux-gnueabihf \
	build-essential \
	bzip2 \
	bzr \
	cmake \
	cmake-curses-gui \
	cpio \
	flex \
	bison \
	g++-arm-linux-gnueabihf \
	gcc-arm-linux-gnueabihf \
	git \
	libc6-dev-armhf-cross \
	libncurses5-dev \
	libtool \
	libtool-bin \
	linux-libc-dev-armhf-cross \
	locales \
	make \
	pkg-config \
	rsync \
	scons \
	squashfs-tools \
	texinfo \
	tree \
	unzip \
	wget

command -v "${TARGET_TRIPLET}-gcc" >/dev/null 2>&1
command -v "${TARGET_TRIPLET}-g++" >/dev/null 2>&1
command -v "${TARGET_TRIPLET}-strip" >/dev/null 2>&1
command -v "${TARGET_TRIPLET}-readelf" >/dev/null 2>&1

GCC_VERSION_DIR="$(find "${GCC_CROSS_DIR}" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"
if [ -z "${GCC_VERSION_DIR}" ]; then
	echo "missing gcc cross support dir under ${GCC_CROSS_DIR}" >&2
	exit 1
fi

rm -rf "${SYSROOT_DIR}"
mkdir -p \
	"${SYSROOT_DIR}/lib" \
	"${SYSROOT_DIR}/usr/lib" \
	"${SYSROOT_DIR}/usr/include" \
	"${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" \
	"${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/include" \
	"${SYSROOT_DIR}/usr/lib/gcc/${TARGET_TRIPLET}/$(basename "${GCC_VERSION_DIR}")"

# Minimal sysroot: keep the full libc header set, but only stage the runtime,
# linker scripts, startup objects, and GCC support files needed to compile and
# link against the target.
copy_tree "/usr/${TARGET_TRIPLET}/include" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/include"
copy_tree "/usr/${TARGET_TRIPLET}/include" "${SYSROOT_DIR}/usr/include"

copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "crt*.o"
copy_matches "${GCC_VERSION_DIR}" "${SYSROOT_DIR}/usr/lib/gcc/${TARGET_TRIPLET}/$(basename "${GCC_VERSION_DIR}")" "crt*.o"

copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "ld-linux-armhf.so.3"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "libc.so*"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "libpthread.so*"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "libm.so*"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "libdl.so*"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "libresolv.so*"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "librt.so*"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "libutil.so*"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "libgcc_s.so*"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "libstdc++.so*"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "libatomic.so*"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "libasan.so*"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "libubsan.so*"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/${TARGET_TRIPLET}/lib" "*_nonshared.a"

copy_matches "/lib/${TARGET_TRIPLET}" "${SYSROOT_DIR}/lib" "ld-linux-armhf.so.3"
copy_matches "/lib/${TARGET_TRIPLET}" "${SYSROOT_DIR}/lib" "libc.so.6"
copy_matches "/lib/${TARGET_TRIPLET}" "${SYSROOT_DIR}/lib" "libpthread.so.0"
copy_matches "/lib/${TARGET_TRIPLET}" "${SYSROOT_DIR}/lib" "libm.so.6"
copy_matches "/lib/${TARGET_TRIPLET}" "${SYSROOT_DIR}/lib" "libdl.so.2"
copy_matches "/lib/${TARGET_TRIPLET}" "${SYSROOT_DIR}/lib" "libresolv.so.2"
copy_matches "/lib/${TARGET_TRIPLET}" "${SYSROOT_DIR}/lib" "librt.so.1"
copy_matches "/lib/${TARGET_TRIPLET}" "${SYSROOT_DIR}/lib" "libutil.so.1"
copy_matches "/lib/${TARGET_TRIPLET}" "${SYSROOT_DIR}/lib" "libgcc_s.so.1"
copy_matches "/lib/${TARGET_TRIPLET}" "${SYSROOT_DIR}/lib" "libstdc++.so.6*"
copy_matches "/lib/${TARGET_TRIPLET}" "${SYSROOT_DIR}/lib" "libatomic.so.1*"
copy_matches "/lib/${TARGET_TRIPLET}" "${SYSROOT_DIR}/lib" "libasan.so.*"
copy_matches "/lib/${TARGET_TRIPLET}" "${SYSROOT_DIR}/lib" "libubsan.so.*"

copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/lib" "libc.so"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/lib" "libpthread.so"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/lib" "libm.so"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/lib" "libdl.so"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/lib" "libresolv.so"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/lib" "librt.so"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/lib" "libutil.so"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/lib" "libstdc++.so"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/lib" "libgcc_s.so"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/lib" "libatomic.so"
copy_matches "/usr/${TARGET_TRIPLET}/lib" "${SYSROOT_DIR}/usr/lib" "*_nonshared.a"

copy_matches "${GCC_VERSION_DIR}" "${SYSROOT_DIR}/usr/lib/gcc/${TARGET_TRIPLET}/$(basename "${GCC_VERSION_DIR}")" "libgcc.a"
copy_matches "${GCC_VERSION_DIR}" "${SYSROOT_DIR}/usr/lib/gcc/${TARGET_TRIPLET}/$(basename "${GCC_VERSION_DIR}")" "libgcc_eh.a"
copy_matches "${GCC_VERSION_DIR}" "${SYSROOT_DIR}/usr/lib/gcc/${TARGET_TRIPLET}/$(basename "${GCC_VERSION_DIR}")" "libgcc_s.so*"
copy_matches "${GCC_VERSION_DIR}" "${SYSROOT_DIR}/usr/lib/gcc/${TARGET_TRIPLET}/$(basename "${GCC_VERSION_DIR}")" "libstdc++.a"
copy_matches "${GCC_VERSION_DIR}" "${SYSROOT_DIR}/usr/lib/gcc/${TARGET_TRIPLET}/$(basename "${GCC_VERSION_DIR}")" "libstdc++.so*"
copy_matches "${GCC_VERSION_DIR}" "${SYSROOT_DIR}/usr/lib/gcc/${TARGET_TRIPLET}/$(basename "${GCC_VERSION_DIR}")" "libsupc++.a"
copy_matches "${GCC_VERSION_DIR}" "${SYSROOT_DIR}/usr/lib/gcc/${TARGET_TRIPLET}/$(basename "${GCC_VERSION_DIR}")" "libatomic.a"
copy_matches "${GCC_VERSION_DIR}" "${SYSROOT_DIR}/usr/lib/gcc/${TARGET_TRIPLET}/$(basename "${GCC_VERSION_DIR}")" "libatomic.so*"
copy_matches "${GCC_VERSION_DIR}" "${SYSROOT_DIR}/usr/lib/gcc/${TARGET_TRIPLET}/$(basename "${GCC_VERSION_DIR}")" "libasan.so*"
copy_matches "${GCC_VERSION_DIR}" "${SYSROOT_DIR}/usr/lib/gcc/${TARGET_TRIPLET}/$(basename "${GCC_VERSION_DIR}")" "libubsan.so*"

printf '%s\n' "Prepared Ubuntu ARMhf sysroot at ${SYSROOT_DIR}"
printf '%s\n' "Target flags: -mcpu=${TARGET_CPU} -mfpu=${TARGET_FPU} -mfloat-abi=${TARGET_FLOAT_ABI} -marm"
