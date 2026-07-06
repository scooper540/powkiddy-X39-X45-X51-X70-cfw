#!/bin/sh

## install needed
sudo apt-get -y update
sudo apt-get -y install \
	bc \
    build-essential \
    bzip2 \
	bzr \
	cmake \
	cmake-curses-gui \
	cpio \
	doxygen \
	git \
	libncurses5-dev \
	locales \
	make \
	rsync \
	scons \
	tree \
	unzip \
	wget \
	pkg-config \
	flex \
	bison \
	autoconf \
	automake \
	libtool \
	ant \
	openjdk-21-jdk-headless \
	7zip \
	p7zip-full

git submodule init
git submodule update

## extract linaro to toolchain
rm -rf sysroot
wget https://developer.arm.com/-/cdn-downloads/permalink/legacy-linaro-gnu-toolchains/7.5-2019.12/sysroot-glibc-linaro-2.25-2019.12-arm-linux-gnueabihf.tar.xz
wget https://developer.arm.com/-/cdn-downloads/permalink/legacy-linaro-gnu-toolchains/7.5-2019.12/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
tar xvf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
tar xvf sysroot-glibc-linaro-2.25-2019.12-arm-linux-gnueabihf.tar.xz
mv sysroot-glibc-linaro-2.25-2019.12-arm-linux-gnueabihf sysroot
cp -rf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/* sysroot/
rm -rf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf
