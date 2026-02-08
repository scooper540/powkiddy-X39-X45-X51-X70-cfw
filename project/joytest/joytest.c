#include <SDL2/SDL.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
    if (SDL_Init(SDL_INIT_JOYSTICK) < 0) {
        fprintf(stderr, "SDL_Init error: %s\n", SDL_GetError());
        return 1;
    }

    int num_joy = SDL_NumJoysticks();
    printf("Found %d joystick(s)\n", num_joy);
    if (num_joy < 1) return 0;

    SDL_Joystick *joy = SDL_JoystickOpen(0);
    if (!joy) {
        fprintf(stderr, "SDL_JoystickOpen error: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    printf("Monitoring joystick: %s\n", SDL_JoystickName(joy));

    SDL_Event e;
    while (1) {
        while (SDL_PollEvent(&e)) {
            switch (e.type) {
                case SDL_JOYAXISMOTION:
                    printf("Axis %d = %d\n", e.jaxis.axis, e.jaxis.value);
                    break;
                case SDL_JOYBUTTONDOWN:
                    printf("Button %d pressed\n", e.jbutton.button);
                    break;
                case SDL_JOYBUTTONUP:
                    printf("Button %d released\n", e.jbutton.button);
                    break;
            }
        }
        SDL_Delay(10); // éviter 100% CPU
    }

    SDL_JoystickClose(joy);
    SDL_Quit();
    return 0;
}

