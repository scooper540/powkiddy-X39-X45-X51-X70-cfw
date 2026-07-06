#/bin/sh

set -e
export NUM_THREAD="$(nproc)"

cd "$(pwd)/project"
source set_env.sh

rm -rf zlib-1.2.8
tar xvf zlib-1.2.8.tar.xz
cd zlib-1.2.8
./configure
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..
ln -sf libz.a $SYSROOT/usr/local/lib/libzlib.a

rm -rf lpng1655
unzip lpng1655.zip
cd lpng1655
./configure --host=$ARMABI --build=$(gcc -dumpmachine) --enable-hardware-optimizations=yes --enable-arm-neon-api=yes
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf jpeg-9c
tar xvzf jpeg-9c.tar.gz
cd jpeg-9c
./configure --host=$ARMABI --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf freetype-2.5.5
tar xvjf freetype-2.5.5.tar.bz2
cd freetype-2.5.5
#export CROSS_PATH=$SYSROOT/bin
./configure --host=$ARMABI --build=$(gcc -dumpmachine)
#PATH="/usr/bin:/bin" ./configure --host=$ARMABI --build=$(gcc -dumpmachine) \
#   CC="$CROSS_PATH/arm-none-linux-gnueabihf-gcc --sysroot=$SYSROOT" \
#   CXX="$CROSS_PATH/arm-none-linux-gnueabihf-g++ --sysroot=$SYSROOT" \
#   AR="$CROSS_PATH/arm-none-linux-gnueabihf-ar" \
#   RANLIB="$CROSS_PATH/arm-none-linux-gnueabihf-ranlib"
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf tslib
git clone https://github.com/libts/tslib.git
cd tslib
./autogen.sh
./configure --host=$ARMABI --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf alsa-lib-1.2.9
tar xvjf alsa-lib-1.2.9.tar.bz2
cd alsa-lib-1.2.9
./configure --host=$ARMABI --enable-shared --disable-python
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

cd SDL-1.2
chmod +x configure
./configure --host=$ARMABI --disable-video-opengl --disable-video-x11 --enable-video-fbcon --enable-joystick --enable-audio --enable-arm-simd --enable-arm-neon --build=$(gcc -dumpmachine) --enable-rpath=no
make clean
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
#update pkg-config sdl because it's searching in rpath host libs...
sed -i 's|-Wl,-rpath,[^ ]*||; s|-lpthread|-lpthread -lasound|' $SYSROOT/usr/local/lib/pkgconfig/sdl.pc
# Drop libtool archives before SDL_image links against SDL to avoid absolute
# dependency paths like /usr/local/lib/libts.la leaking out of DESTDIR installs.
find "$SYSROOT" -name "*.la" -delete
cd ..

rm -rf SDL_image-release-1.2.12
unzip sdl_image-1.2.zip
cd SDL_image-release-1.2.12
./configure --host=$ARMABI --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf SDL_ttf
git clone -b SDL-1.2 --depth 1 https://github.com/libsdl-org/SDL_ttf.git
cd SDL_ttf
./configure --host=$ARMABI --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf mpg123-1.33.4
tar xvjf mpg123-1.33.4.tar.bz2
cd mpg123-1.33.4
 ./configure ./configure --host=$ARMABI --build=$(gcc -dumpmachine) --with-cpu=arm_fpu  --with-network=none  --with-audio=sdl
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf SDL_mixer
git clone -b SDL-1.2 --depth 1 https://github.com/libsdl-org/SDL_mixer.git
cd SDL_mixer
./configure --host=$ARMABI --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf SDL_gfx
git clone https://github.com/ferzkopp/SDL_gfx.git
cd SDL_gfx
./configure --host=$ARMABI --build=$(gcc -dumpmachine) --disable-mmx
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf rapidjson-1.1.0
unzip rapidjson-1.1.0.zip
cp -rf rapidjson-1.1.0/include/rapidjson $SYSROOT/usr/include


#boost
rm -rf boost
git clone -b boost-1.87.0 --depth 1 https://github.com/boostorg/boost.git
cd boost
git submodule init
git submodule update
PATH=/usr/bin:/bin ./bootstrap.sh
cat > project-config.jam <<EOF
using gcc : arm : ${PATHGCC}/${ARMABI}-g++ ;
EOF
./b2 -j"$NUM_THREAD" \
    toolset=gcc-arm \
    install \
    --prefix="${SYSROOT}/usr" \
    architecture=arm \
    target-os=linux \
    link=static,shared \
    --with-system \
    --with-filesystem \
    --with-date_time \
    --with-locale \
    cxxflags="-std=c++11 -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard --sysroot=${SYSROOT}" \
    linkflags="--sysroot=${SYSROOT}" \
    variant=release
rsync -aL boost/ "${SYSROOT}/usr/include/boost/"
cd ..

rm -rf tiff-4.6.0
wget https://download.osgeo.org/libtiff/tiff-4.6.0.tar.gz
tar xf tiff-4.6.0.tar.gz
cd tiff-4.6.0
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf tiff-4.0.10
wget https://download.osgeo.org/libtiff/tiff-4.0.10.tar.gz
tar xf tiff-4.0.10.tar.gz
cd tiff-4.0.10
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine)
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf libwebp-1.2.4
wget https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.2.4.tar.gz
tar xf libwebp-1.2.4.tar.gz
cd libwebp-1.2.4
./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine) --enable-neon
make -j$NUM_THREAD
make install DESTDIR=$SYSROOT
cd ..

rm -rf libmad-0.15.1b
wget https://downloads.sourceforge.net/mad/libmad-0.15.1b.tar.gz
tar xf libmad-0.15.1b.tar.gz
cd libmad-0.15.1b
CFLAGS="${CFLAGS} -marm" ./configure --host=arm-linux-gnueabihf --build=$(gcc -dumpmachine)
make -j$NUM_THREAD CFLAGS="${CFLAGS} -marm"
make install DESTDIR=$SYSROOT
cd ..

rm -rf ffmpeg-4.4.4
if [ ! -f "ffmpeg-4.4.4.tar.bz2" ]; then
    echo "Downloading FFmpeg 4.4.4..."
    wget https://ffmpeg.org/releases/ffmpeg-4.4.4.tar.bz2
fi

echo "Extracting FFmpeg..."
tar xjf ffmpeg-4.4.4.tar.bz2
cd ffmpeg-4.4.4

echo "Configuring FFmpeg (Fully Static)..."
make clean || true
make distclean || true

./configure \
  --prefix=/usr/local \
  --enable-cross-compile \
  --cross-prefix="${ARMABI}-" \
  --target-os=linux \
  --arch=arm \
  --cpu=cortex-a9 \
  --sysroot="${SYSROOT}" \
  --extra-cflags="-mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard" \
  --extra-ldflags="--sysroot=${SYSROOT}" \
  --disable-shared \
  --enable-static \
  --enable-filters \
  --enable-alsa \
  --disable-vdpau \
  --disable-vaapi \
  --enable-gpl \
  --enable-nonfree

echo "Building FFmpeg..."
make -j$NUM_THREAD

echo "Installing FFmpeg to Sysroot..."
make install DESTDIR="$SYSROOT"

cd ..
