#include <linux/input.h>
#include <fcntl.h>
#include <unistd.h>

#define INPUT_DEV "/dev/input/event1"

static int in_fd;

void input_init(void) {
    in_fd = open(INPUT_DEV, O_RDONLY);
}

int ev_poll(int sleep) {
    struct input_event ev;
    input_init();
    if (read(in_fd, &ev, sizeof(ev)) > 0 && ev.type == EV_KEY && ev.value == 1) {
/*        switch(ev.code) {
            // D-Pad
            case 103: return UP;
            case 106: return RIGHT;
            case 108: return DOWN;
            case 105: return LEFT;

            // Buttons
            case 352: return A;
            case 158: return B;
            case 308: return X;
            case 139: return Y;

            // System
            case 315: return START;
            case 314: return SELECT;
            case 174: return MENU;

            // Shoulders
            case 412: return L1;
            case 407: return R1;
            case 312: return L2;
            case 313: return R2;
        }*/
    }
    return 0;
}

