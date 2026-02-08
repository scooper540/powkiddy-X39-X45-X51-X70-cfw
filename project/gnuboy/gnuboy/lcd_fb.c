#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdio.h>

#define FB_DEV "/dev/fb0"
#define WIDTH 854
#define HEIGHT 480
#define STRIDE 960

static int fb_fd;
static uint16_t *fb;

void lcd_init(void) {
    fb_fd = open(FB_DEV, O_RDWR);
    if (fb_fd < 0) { perror("open fb"); return; }

    fb = mmap(NULL, STRIDE * HEIGHT * 2, PROT_READ|PROT_WRITE, MAP_SHARED, fb_fd, 0);
    if (fb == MAP_FAILED) { perror("mmap fb"); return; }
}

// Simple copy Game Boy 160x144 to top-left of LCD
void lcd_draw(uint16_t *pixels) {
    for (int y = 0; y < 144; y++) {
        uint16_t *row = fb + y * STRIDE;
        for (int x = 0; x < 160; x++) {
            row[x] = pixels[y * 160 + x];
        }
    }
}

