#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <linux/input.h>
#include <stdint.h>
#include <stdio.h>

#define FB_DEV "/dev/fb0"
#define INPUT_DEV "/dev/input/event1"

#define WIDTH 854
#define HEIGHT 480
#define STRIDE 960

// RGB565
#define RED     0xF800
#define GREEN   0x07E0
#define BLUE    0x001F
#define WHITE   0xFFFF
#define BLACK   0x0000
#define YELLOW  0xFFE0
#define CYAN    0x07FF
#define MAGENTA 0xF81F

static uint16_t *fb;
static int fb_fd, in_fd;

void clear(uint16_t color)
{
    for (int y = 0; y < HEIGHT; y++) {
        uint16_t *row = fb + y * STRIDE;
        for (int x = 0; x < WIDTH; x++) {
            row[x] = color;
        }
    }
}

int main(void)
{
    struct input_event ev;

    // framebuffer
    fb_fd = open(FB_DEV, O_RDWR);
    if (fb_fd < 0) {
        perror("open fb");
        return 1;
    }

    fb = mmap(NULL, STRIDE * HEIGHT * 2,
              PROT_READ | PROT_WRITE,
              MAP_SHARED, fb_fd, 0);
    if (fb == MAP_FAILED) {
        perror("mmap fb");
        return 2;
    }

    // input
    in_fd = open(INPUT_DEV, O_RDONLY);
    if (in_fd < 0) {
        perror("open input");
        return 3;
    }

    clear(BLACK);
    printf("Powkiddy framebuffer + input test running\n");

    while (1) {
        int r = read(in_fd, &ev, sizeof(ev));
        if (r <= 0) continue;

        if (ev.type != EV_KEY || ev.value == 0)
            continue; // ignore release

        printf("KEY %d pressed\n", ev.code);
        fflush(stdout);

        switch (ev.code) {

        // D-Pad
        case 103: clear(RED);     break; // UP
        case 106: clear(GREEN);   break; // RIGHT
        case 108: clear(BLUE);    break; // DOWN
        case 105: clear(WHITE);   break; // LEFT

        // Buttons
        case 352: clear(YELLOW);  break; // A
        case 158: clear(CYAN);    break; // B
        case 308: clear(MAGENTA); break; // X
        case 139: clear(RED);     break; // Y

        // System
        case 315: clear(GREEN);   break; // START
        case 314: clear(BLUE);    break; // SELECT
        case 174: clear(WHITE);   break; // MENU

        // Shoulder
        case 412: clear(YELLOW);  break; // L1
        case 407: clear(CYAN);    break; // R1
        case 312: clear(MAGENTA); break; // L2
        case 313: clear(RED);     break; // R2

        // Volume
        case 115: clear(WHITE);   break; // VOL+
        case 114: clear(BLACK);   break; // VOL-
        }
    }

    return 0;
}

