/*
 * sdl.c
 * sdl interfaces -- based on svga.c
 *
 * (C) 2001 Damian Gryski <dgryski@uwaterloo.ca>
 *
 * Licensed under the GPLv2, or later.
 */

#include <stdlib.h>
#include <stdio.h>

#include <SDL/SDL.h>

#include <linux/input.h>
#include <fcntl.h>
#include <unistd.h>

#include "fb.h"
#include "input.h"
#include "rc.h"
#include <poll.h>

extern void sdljoy_process_event(SDL_Event *event);
struct fb fb;

static int use_yuv = -1;
static int fullscreen = 0;
static int use_altenter = 1;

static SDL_Surface *screen;
static SDL_Overlay *overlay;
static SDL_Rect overlay_rect;

static int vmode[3] = { 0, 0, 16 };

static int in_fd;
#define INPUT_DEV "/dev/input/event1"


rcvar_t vid_exports[] =
{
	RCV_VECTOR("vmode", &vmode, 3, "video mode: w h bpp"),
	RCV_BOOL("yuv", &use_yuv, "try to use hardware YUV scaling"),
	RCV_BOOL("fullscreen", &fullscreen, "whether to start in fullscreen mode"),
	RCV_BOOL("altenter", &use_altenter, "alt-enter can toggle fullscreen"),
	RCV_END
};

/* keymap - mappings of the form { scancode, localcode } - from sdl/keymap.c */
extern int keymap[][2];

static int mapscancode(SDLKey sym)
{
	/* this could be faster:  */
	/*  build keymap as int keymap[256], then ``return keymap[sym]'' */

	int i;
	for (i = 0; keymap[i][0]; i++)
		if (keymap[i][0] == sym)
			return keymap[i][1];
	if (sym >= '0' && sym <= '9')
		return sym;
	if (sym >= 'a' && sym <= 'z')
		return sym;
	return 0;
}

static void overlay_init()
{
	if (!use_yuv) return;

	if (use_yuv < 0)
		if (vmode[0] < 320 || vmode[1] < 288)
			return;

	overlay = SDL_CreateYUVOverlay(320, 144, SDL_YUY2_OVERLAY, screen);

	if (!overlay) return;

	if (!overlay->hw_overlay || overlay->planes > 1)
	{
		SDL_FreeYUVOverlay(overlay);
		overlay = 0;
		return;
	}

	SDL_LockYUVOverlay(overlay);

	fb.w = 160;
	fb.h = 144;
	fb.pelsize = 4;
	fb.pitch = overlay->pitches[0];
	fb.ptr = overlay->pixels[0];
	fb.yuv = 1;
	fb.cc[0].r = fb.cc[1].r = fb.cc[2].r = fb.cc[3].r = 0;
	fb.dirty = 1;
	fb.enabled = 1;

	overlay_rect.x = 0;
	overlay_rect.y = 0;
	overlay_rect.w = vmode[0];
	overlay_rect.h = vmode[1];

	/* Color channels are 0=Y, 1=U, 2=V, 3=Y1 */
	switch (overlay->format)
	{
		/* FIXME - support more formats */
	case SDL_YUY2_OVERLAY:
	default:
		fb.cc[0].l = 0;
		fb.cc[1].l = 24;
		fb.cc[2].l = 8;
		fb.cc[3].l = 16;
		break;
	}

	SDL_UnlockYUVOverlay(overlay);
}

void vid_init()
{
printf("open event1\r\n");
in_fd = open(INPUT_DEV, O_RDONLY);
printf("end open event1\r\n");
	struct input_event ev2;
read(in_fd, &ev2, sizeof(ev2));
printf("end open event2\r\n");
	int flags;

	if (!vmode[0] || !vmode[1])
	{
		int scale = rc_getint("scale");
		if (scale < 1) scale = 1;
		vmode[0] = 160 * scale;
		vmode[1] = 144 * scale;
	}
	
	flags = SDL_ANYFORMAT | SDL_HWPALETTE | SDL_HWSURFACE;

	if (fullscreen)
		flags |= SDL_FULLSCREEN;
printf("before sdlinit \r\n");
	if (SDL_Init(SDL_INIT_VIDEO))
		die("SDL: Couldn't initialize SDL: %s\n", SDL_GetError());
printf("end  sdlinit \r\n");
	if (!(screen = SDL_SetVideoMode(vmode[0], vmode[1], vmode[2], flags)))
		die("SDL: can't set video mode: %s\n", SDL_GetError());
printf("before show czurose\r\n");

	SDL_ShowCursor(0);
printf("after show czurose\r\n");
	overlay_init();
printf("after show czurose\r\n");
	if (fb.yuv) return;

	SDL_LockSurface(screen);

	fb.w = screen->w;
	fb.h = screen->h;
	fb.pelsize = screen->format->BytesPerPixel;
	fb.pitch = screen->pitch;
	fb.indexed = fb.pelsize == 1;
	fb.ptr = screen->pixels;
	fb.cc[0].r = screen->format->Rloss;
	fb.cc[0].l = screen->format->Rshift;
	fb.cc[1].r = screen->format->Gloss;
	fb.cc[1].l = screen->format->Gshift;
	fb.cc[2].r = screen->format->Bloss;
	fb.cc[2].l = screen->format->Bshift;

	SDL_UnlockSurface(screen);

	fb.enabled = 1;
	fb.dirty = 0;
printf("end init\r\n");

}


void ev_poll(int wait)
{

	event_t ev;
	SDL_Event event;
	(void) wait;

	while (SDL_PollEvent(&event))
	{


		switch(event.type)
		{
		case SDL_ACTIVEEVENT:
			if (event.active.state == SDL_APPACTIVE)
				fb.enabled = event.active.gain;
			break;
		case SDL_KEYDOWN:
			if ((event.key.keysym.sym == SDLK_RETURN) && (event.key.keysym.mod & KMOD_ALT))
				SDL_WM_ToggleFullScreen(screen);
			ev.type = EV_PRESS;
			ev.code = mapscancode(event.key.keysym.sym);
			ev_postevent(&ev);
			break;
		case SDL_KEYUP:
			ev.type = EV_RELEASE;
			ev.code = mapscancode(event.key.keysym.sym);
			ev_postevent(&ev);
			break;
		case SDL_JOYHATMOTION:
		case SDL_JOYAXISMOTION:
		case SDL_JOYBUTTONUP:
		case SDL_JOYBUTTONDOWN:
			sdljoy_process_event(&event);
			break;
		case SDL_QUIT:
			exit(1);
			break;
		default:
			break;
		}
	}
/*
printf("test key\r\n");
//check if key pressed
printf("%d\r\n", in_fd);
	struct input_event ev2;
struct pollfd pfd = {
    .fd = in_fd,
    .events = POLLIN
};
int ret = poll(&pfd, 1, 0); // timeout 0 = non bloquant
if (ret > 0 && (pfd.revents & POLLIN)) {
    read(in_fd, &ev2, sizeof(ev2));
}

	printf("event\r\n");
	if (ev2.type != EV_KEY) return;
	printf("key event\r\n");
	if(ev2.value == 0)
		ev.type = EV_RELEASE;
	else
		ev.type = EV_PRESS;
	        switch (ev.code) {

        // D-Pad
        case 103: ev.code = K_UP; break;//(RED);     break; // UP
        case 106: ev.code = K_RIGHT;break; // RIGHT
        case 108: ev.code = K_DOWN; break; // DOWN
        case 105: ev.code = K_LEFT; break; // LEFT

        // Buttons
        case 352: ev.code =  K_JOY0; break; // A
        case 158: ev.code =  K_JOY1; break; // B
        case 308: ev.code =  K_JOY2; break; // X
        case 139: ev.code =  K_JOY3; break; // Y

        // System
        case 315: ev.code = K_ENTER; break; // START
        case 314: ev.code = K_SPACE; break; // SELECT
        case 174: ev.code = K_TAB;  break; // MENU

   */     // Shoulder
      /*  case 412: clear(YELLOW);  break; // L1
        case 407: clear(CYAN);    break; // R1
        case 312: clear(MAGENTA); break; // L2
        case 313: clear(RED);     break; // R2

        // Volume
        case 115: clear(WHITE);   break; // VOL+
        case 114: clear(BLACK);   break; // VOL-*/
     //   }
	ev_postevent(&ev);


}

void vid_setpal(int i, int r, int g, int b)
{
	SDL_Color col;

	col.r = r; col.g = g; col.b = b;

	SDL_SetColors(screen, &col, i, 1);
}

void vid_preinit()
{
}

void vid_close()
{
	if (overlay)
	{
		SDL_UnlockYUVOverlay(overlay);
		SDL_FreeYUVOverlay(overlay);
	}
	else SDL_UnlockSurface(screen);
	SDL_Quit();
	fb.enabled = 0;
}

void vid_settitle(char *title)
{
	SDL_WM_SetCaption(title, title);
}

void vid_begin()
{
	if (overlay)
	{
		SDL_LockYUVOverlay(overlay);
		fb.ptr = overlay->pixels[0];
		return;
	}
	SDL_LockSurface(screen);
	fb.ptr = screen->pixels;
}

void vid_end()
{
	if (overlay)
	{
		SDL_UnlockYUVOverlay(overlay);
		if (fb.enabled)
			SDL_DisplayYUVOverlay(overlay, &overlay_rect);
		return;
	}
	SDL_UnlockSurface(screen);
	if (fb.enabled) SDL_Flip(screen);
}








