#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdint.h>

int main() {
    int fb = open("/dev/fb0", O_RDWR);
    if (fb < 0) { perror("open fb0"); return 1; }

    // mmap framebuffer (854*480*2 bytes pour RGB565)
    uint16_t *screen = mmap(NULL, 854*480*2, PROT_WRITE, MAP_SHARED, fb, 0);
    if (screen == MAP_FAILED) { perror("mmap"); return 1; }

    // remplissage rouge
    for (int i=0; i<854*480; i++) screen[i] = 0xFF00; // RGB565 rouge

    sleep(3);

    munmap(screen, 854*480*2);
    close(fb);
    return 0;
}

