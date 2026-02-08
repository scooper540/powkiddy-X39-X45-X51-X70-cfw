
prefix = /tmp/gnuboy-install
exec_prefix = ${prefix}
bindir = ${exec_prefix}/bin

CC = arm-gcc
LD = $(CC)
AS = $(CC)
INSTALL = /usr/bin/install -c

CFLAGS =  -Wno-unused-function -Wno-deprecated-declarations -Wno-overlength-strings -Wall -O3 -fstrength-reduce -fthread-jumps  -fcse-follow-jumps -fcse-skip-blocks -frerun-cse-after-loop  -fexpensive-optimizations -fforce-addr -fomit-frame-pointer
CPPFLAGS = 
LDFLAGS = $(CFLAGS)  -s 
ASFLAGS = $(CFLAGS)

TARGETS =  fbgnuboy sdlgnuboy

ASM_OBJS = 

SYS_DEFS = -DHAVE_CONFIG_H -DIS_LITTLE_ENDIAN  
SYS_OBJS = sys/nix/nix.o $(ASM_OBJS)
SYS_INCS =  -I./sys/nix

FB_OBJS = sys/linux/fbdev.o sys/linux/kb.o sys/pc/keymap.o sys/linux/joy.o sys/dummy/nosound.o
FB_LIBS = 

SVGA_OBJS = sys/svga/svgalib.o sys/pc/keymap.o sys/linux/joy.o sys/dummy/nosound.o
SVGA_LIBS = -L/usr/local/lib -lvga

SDL_OBJS = sys/sdl/sdl.o sys/sdl/sdl-audio.o sys/sdl/keymap.o sys/sdl/sdl-joystick.o
SDL_LIBS = -lSDL
SDL_CFLAGS = 

SDL2_OBJS = sys/sdl2/sdl2.o sys/sdl2/sdl-audio.o sys/sdl2/keymap.o sys/sdl2/sdl-joystick.o
SDL2_LIBS = 

X11_OBJS = sys/x11/xlib.o sys/x11/keymap.o sys/linux/joy.o sys/dummy/nosound.o
X11_LIBS =  -lX11 -lXext

all: $(TARGETS)

include Rules

fbgnuboy: $(OBJS) $(SYS_OBJS) $(FB_OBJS)
	$(LD) $(OBJS) $(SYS_OBJS) $(FB_OBJS) -o $@ $(FB_LIBS) $(LDFLAGS)

sgnuboy: $(OBJS) $(SYS_OBJS) $(SVGA_OBJS)
	$(LD) $(OBJS) $(SYS_OBJS) $(SVGA_OBJS) -o $@ $(SVGA_LIBS) $(LDFLAGS)

sdlgnuboy: $(OBJS) $(SYS_OBJS) $(SDL_OBJS)
	$(LD) $(OBJS) $(SYS_OBJS) $(SDL_OBJS) -o $@ $(SDL_LIBS) $(LDFLAGS)

sdl2gnuboy: $(OBJS) $(SYS_OBJS) $(SDL2_OBJS)
	$(LD) $(OBJS) $(SYS_OBJS) $(SDL2_OBJS) -o $@ $(SDL2_LIBS) $(LDFLAGS)

sys/sdl/sdl.o: sys/sdl/sdl.c
	$(MYCC) $(SDL_CFLAGS) -c $< -o $@

sys/sdl/keymap.o: sys/sdl/keymap.c
	$(MYCC) $(SDL_CFLAGS) -c $< -o $@

xgnuboy: $(OBJS) $(SYS_OBJS) $(X11_OBJS)
	$(LD) $(OBJS) $(SYS_OBJS) $(X11_OBJS) -o $@ $(X11_LIBS) $(LDFLAGS)

joytest: joytest.o sys/linux/joy.o
	$(LD) $^ -o $@ $(LDFLAGS)

install: all
	$(INSTALL) -d $(bindir)
	$(INSTALL) -m 755 $(TARGETS) $(bindir)

clean:
	rm -f *gnuboy gmon.out *.o sys/*.o sys/*/*.o asm/*/*.o $(OBJS)

distclean: clean
	rm -f config.* sys/nix/config.h Makefile




