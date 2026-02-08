#include <fcntl.h>
#include <unistd.h>
#include <linux/input.h>
#include <stdio.h>
#include <errno.h>

#define INPUT_DEV "/dev/input/event1"   // change si besoin

int main(void)
{
    int fd = open(INPUT_DEV, O_RDONLY);
    if (fd < 0) {
        perror("open input");
        return 1;
    }

    printf("Listening on %s\n", INPUT_DEV);

    struct input_event ev;

    while (1) {
        int r = read(fd, &ev, sizeof(ev));
        if (r < 0) {
            perror("read");
            break;
        }

        if (ev.type == EV_KEY) {
            printf("KEY code=%d value=%d\n", ev.code, ev.value);
            fflush(stdout);
        }
    }

    return 0;
}

