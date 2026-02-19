#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <linux/uinput.h>
#include <linux/input.h>
#include <time.h>

void emit(int fd, int type, int code, int val) {
    struct input_event ie;
    ie.type = type;
    ie.code = code;
    ie.value = val;
    ie.time.tv_sec = 0;
    ie.time.tv_usec = 0;
    write(fd, &ie, sizeof(ie));
}

// Mode: 0=Click, 1=Scroll Up, 2=Scroll Down, 3=Move Up, 4=Move Down, 5=Move Left, 6=Move Right, 8=Random Move
int main(int argc, char *argv[]) {
    if (argc < 4) {
        printf("Usage: %s <mode> <count> <delay_us>\n", argv[0]);
        printf("Modes: 0=Click, 1=Scroll Up, 2=Scroll Down, 3=Move Up, 4=Move Down, 5=Move Left, 6=Move Right, 8=Random Move\n");
        return 1;
    }
    
    srand(time(NULL)); // Seed random number generator

    int mode = atoi(argv[1]);
    int count = atoi(argv[2]);
    int delay = atoi(argv[3]);

    int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (fd < 0) {
        perror("Error opening /dev/uinput");
        return 1;
    }

    // Setup uinput device
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_KEYBIT, BTN_LEFT);
    
    ioctl(fd, UI_SET_EVBIT, EV_REL);
    ioctl(fd, UI_SET_RELBIT, REL_WHEEL);
    ioctl(fd, UI_SET_RELBIT, REL_X);
    ioctl(fd, UI_SET_RELBIT, REL_Y);
    
    struct uinput_setup usetup;
    memset(&usetup, 0, sizeof(usetup));
    usetup.id.bustype = BUS_USB;
    usetup.id.vendor = 0x1234;
    usetup.id.product = 0x5679;
    strcpy(usetup.name, "Turbo Mouse Injector");

    ioctl(fd, UI_DEV_SETUP, &usetup);
    ioctl(fd, UI_DEV_CREATE);

    // Wait for device creation
    usleep(100000); // 100ms

    int step = 10; // Pixel movement per event

    for (int i = 0; i < count; i++) {
        if (mode == 0) { // Click
            emit(fd, EV_KEY, BTN_LEFT, 1);
            emit(fd, EV_SYN, SYN_REPORT, 0);
            if (delay > 0) usleep(delay);
            emit(fd, EV_KEY, BTN_LEFT, 0);
            emit(fd, EV_SYN, SYN_REPORT, 0);
        } else if (mode == 1) { // Scroll Up
            emit(fd, EV_REL, REL_WHEEL, 1);
            emit(fd, EV_SYN, SYN_REPORT, 0);
        } else if (mode == 2) { // Scroll Down
            emit(fd, EV_REL, REL_WHEEL, -1);
            emit(fd, EV_SYN, SYN_REPORT, 0);
        } else if (mode == 3) { // Move Up
            emit(fd, EV_REL, REL_Y, -step);
            emit(fd, EV_SYN, SYN_REPORT, 0);
        } else if (mode == 4) { // Move Down
            emit(fd, EV_REL, REL_Y, step);
            emit(fd, EV_SYN, SYN_REPORT, 0);
        } else if (mode == 5) { // Move Left
            emit(fd, EV_REL, REL_X, -step);
            emit(fd, EV_SYN, SYN_REPORT, 0);
        } else if (mode == 6) { // Move Right
            emit(fd, EV_REL, REL_X, step);
            emit(fd, EV_SYN, SYN_REPORT, 0);
        } else if (mode == 8) { // Random Move
            int rx = (rand() % 21) - 10; // -10 to 10
            int ry = (rand() % 21) - 10; // -10 to 10
            
            if (rx != 0) {
                emit(fd, EV_REL, REL_X, rx);
                emit(fd, EV_SYN, SYN_REPORT, 0);
            }
            if (ry != 0) {
                emit(fd, EV_REL, REL_Y, ry);
                emit(fd, EV_SYN, SYN_REPORT, 0);
            }
        }
        
        if (delay > 0) usleep(delay);
        
        // Progress update
        if ((i + 1) % 100 == 0 || i == count - 1) {
            printf("\rAction: %d/%d", i + 1, count);
            fflush(stdout);
        }
    }
    
    printf("\n");

    ioctl(fd, UI_DEV_DESTROY);
    close(fd);
    return 0;
}
