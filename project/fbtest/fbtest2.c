#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdint.h>

#define WIDTH 854   // résolution physique
#define HEIGHT 480
#define STRIDE 960  // pixels par ligne

int main() {
    int fb = open("/dev/fb0", O_RDWR);
    if (fb < 0) { perror("open fb0"); return 1; }

//    uint16_t *screen = mmap(NULL, STRIDE*2562*2, PROT_WRITE, MAP_SHARED, fb, 0);
uint16_t *screen = mmap(NULL, STRIDE*HEIGHT*2, PROT_WRITE, MAP_SHARED, fb, 0);
    if (screen == MAP_FAILED) { perror("mmap"); return 1; }

    for (int y=0; y<HEIGHT; y++) {
        for (int x=0; x<WIDTH; x++) {
            screen[y*STRIDE + x] = 0xF800; // rouge RGB565
        }
    }

    sleep(3);

    munmap(screen, STRIDE*2562*2);
    close(fb);
    return 0;
}

