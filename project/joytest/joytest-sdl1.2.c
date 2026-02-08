#include <stdio.h>
#include <stdlib.h>
#include <SDL/SDL.h>

int main(int argc, char *argv[])
{
    SDL_Event event;

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK) < 0) {
        printf("SDL_Init failed: %s\n", SDL_GetError());
        return 1;
    }

    printf("SDL initialized\n");

    /* Dummy video mode (required by SDL 1.2) */
    SDL_SetVideoMode(16, 16, 16, SDL_SWSURFACE);

    if (SDL_NumJoysticks() > 0) {
        SDL_JoystickOpen(0);
        printf("Joystick opened\n");
    } else {
        printf("No joystick detected (keys may still work)\n");
    }

    while (1) {
        while (SDL_PollEvent(&event)) {
            switch (event.type) {

            case SDL_KEYDOWN:
                printf("KEY DOWN: sym=%d scancode=%d\n",
                       event.key.keysym.sym,
                       event.key.keysym.scancode);
                break;

            case SDL_KEYUP:
                printf("KEY UP  : sym=%d scancode=%d\n",
                       event.key.keysym.sym,
                       event.key.keysym.scancode);
                break;

            case SDL_JOYBUTTONDOWN:
                printf("JOY BUTTON DOWN: %d\n", event.jbutton.button);
                break;

            case SDL_JOYBUTTONUP:
                printf("JOY BUTTON UP  : %d\n", event.jbutton.button);
                break;

            case SDL_JOYAXISMOTION:
                printf("JOY AXIS %d value %d\n",
                       event.jaxis.axis,
                       event.jaxis.value);
                break;

            case SDL_QUIT:
                goto out;
            }
        }

        SDL_Delay(10);
    }

out:
    SDL_Quit();
    return 0;
}
