
## Powkiddy x39pro/x45/x51/x70 toolchain to compile custom binaries

**What is working**
joysticks and buttons
framebuffer

**no audio at this moment**

**How to use:**
 - Install ubuntu 16.04 64 bits
 - Get this repository
   -     I've pushed the buildroot output folder, I hope it can work on other VM ..., if not you have to : make toolchain
  - In order to compile something with the toolchain, apply the environments variables defined in [project/how-to](https://github.com/scooper540/powkiddy-X39-X45-X51-X70-cfw/blob/main/project/how-to)
   - SDL1-2 has been modified to be able to use the framebuffer with correct resolution
   - push the binary to the console
   - apply the export on the consoles
   - start :-)
 - gnuboy is included in this project as a PoC
 - Firmware directory contains the scripts to extract the various partitions of the FW, a repack for update.zip to flash the consoles is possible as well (thanks [fox_exe ](https://github.com/FoxExe/PowKiddy_fw) )
