# PowKiddy firmware modification utilities

- Tested on PowKiddy X70
- Required python3.7 and later for work.
- For update firmware: Upload "update.zip" to root folder of SD (TF) card and power on device

##### What done? Plans?
- [x] Firmware OTA (update.zip) unpack
- [x] Firmware OTA (update.zip) creation
- [x] Firmware (.fw) unpacker
- [ ] Firmware (.fw) creation
- [ ] Firmware uploader (ADFU)
- [ ] .res and .str packer/unpacker tools (image and text resources files)
- [ ] .sty editor (Style/theme description file)
- [ ] More languages support?
- [ ] Custom theme?
- [ ] Add support for PS and XBox gamepads
- [ ] Add usb-lan/wifi modules support? (Device already have hidden browser!)
- [ ] More applications?

##### Hardware:
**CPU:** ACTIONS OWL SoC, 4-core @ 1.3GHz, Cortex-A9, ARMv7l (ATM7051H ZH72NMP 25C)  
**GPU:** PowerVR SGX540 (??)  
**RAM:** 256MB DDR3 (SEC 816 K4B2G16 46F BYMA)  
**ROM:** 128MB Nand (Spansion, S34ML01G200TF100)  
**LCD:** 1024x600 TFT panel + HDMI output (with sound)  
**AUD:** 2xHAA2018 (Class F audio amplifiers, 6-12W)  
**PWR:** ATT3002  
**BAT:** Li-po, 3500mAh, 3.7v (12.95Wh)  
**LCD:** KHX070BG-27A (20220928)  

##### NAND partitions:
|  # |     Name |  Type |    Start |     Size |
| -- | -------- | ----- | -------- | -------- |
|    |   U-Boot |   RAW |        0 |  4194304 |
|  0 |     MISC | FAT16 |  4194304 |  8388608 |
|  1 | RECOVERY | FAT16 | 12582912 | 10485760 |
|  2 |   CONFIG |   RAW | 23199744 |   131072 |
|  3 |   SYSTEM |  SQFS | 23199744 | 33554432 |
|  4 |  UPGRADE | FAT32 | 56754176 |  5242880 |
|  5 |      RES |  SQFS | 61997056 | 31457280 |
|  6 |    UDISK | FAT32 | 93454336 | 31308800 |
