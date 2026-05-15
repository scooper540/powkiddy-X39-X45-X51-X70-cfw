#/bin/sh

set -e
export NUM_THREAD="$(nproc)"

cd "$(pwd)/project"
source set_env.sh

export TARGET_CORE_FLAGS="${TARGET_OPT_FLAGS} ${TARGET_ARCH_FLAGS}"
export TARGET_CORE_LDFLAGS="-Wl,--as-needed -Wl,--gc-sections ${TARGET_ARCH_FLAGS} --sysroot=${SYSROOT} -L${SYSROOT}/usr/local/lib -L${SYSROOT}/usr/lib -L${SYSROOT}/lib"
export CFLAGS="${TARGET_CORE_FLAGS} -fno-plt"
export CXXFLAGS="${TARGET_CORE_FLAGS} -fno-plt"
export CPPFLAGS="${TARGET_CORE_FLAGS}"
export LDFLAGS="${TARGET_CORE_LDFLAGS}"

build_core() {
	core_name="$1"
	./libretro-fetch.sh "$core_name"
	platform=classic_armv7_a7 ./libretro-build.sh "$core_name"
}

git clone https://github.com/libretro/libretro-super.git
cd libretro-super
build_core 2048
build_core mrboom
build_core prboom
build_core gambatte
build_core gearboy
build_core gpsp
build_core mgba
build_core tgbdual
build_core vbam
build_core fceumm
build_core nestopia
build_core quicknes
build_core snes9x2002
build_core snes9x2005
build_core snes9x2010
build_core snes9x
build_core mednafen_supafaust
build_core genesis_plus_gx
build_core picodrive
build_core pcsx_rearmed
build_core fbneo
build_core mame2000
build_core mame2003
build_core mame2003_plus
build_core fbalpha2012
build_core mednafen_ngp
build_core mednafen_vb
build_core freeintv
build_core mednafen_lynx

./libretro-fetch.sh retro8
CFLAGS="${TARGET_CORE_FLAGS} -fno-plt -DUSE_RGB565" platform=classic_armv7_a7 ./libretro-build.sh retro8

./libretro-fetch.sh vice_xvic
platform=classic_armv7_a7 ./libretro-build.sh vice_xvic -j"$NUM_THREAD"
./libretro-fetch.sh vice_x64
platform=classic_armv7_a7 ./libretro-build.sh vice_x64 -j"$NUM_THREAD"

#download cores from buildbot
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/atari800_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/bluemsx_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/cap32_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/freechaf_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/fuse_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/gw_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/handy_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/mednafen_pce_fast_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/mednafen_pce_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/mednafen_supergrafx_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/mednafen_wswan_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/o2em_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/pokemini_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/prosystem_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/puae_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/scummvm_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/tic80_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
wget -O /tmp/file.zip "https://buildbot.libretro.com/nightly/linux/armv7-neon-hf/latest/vecx_libretro.so.zip" && unzip /tmp/file.zip -d dist/unix
# all cores are stored on SD Card
cp -rf dist/unix/* "$(pwd)/../../output-sd/cfw/retroarch/cores/"

cd ..
git clone https://github.com/schellingb/dosbox-pure.git
cd dosbox-pure
CFLAGS="${TARGET_CORE_FLAGS} -fno-plt" CXXFLAGS="${TARGET_CORE_FLAGS} -fno-plt" LDFLAGS="${TARGET_CORE_LDFLAGS}" platform=classic_armv7_a7 make -j"$NUM_THREAD"
cp  dosbox_pure_libretro.so $(pwd)/../../output-sd/cfw/retroarch/cores/
