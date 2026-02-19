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

int get_keycode(char c) {
    if (c >= 'a' && c <= 'z') return KEY_A + (c - 'a');
    if (c >= 'A' && c <= 'Z') return KEY_A + (c - 'A'); // Simplified: ignores Shift logic for now
    if (c >= '0' && c <= '9') return KEY_0 + (c - '0');
    if (c == ' ') return KEY_SPACE;
    if (c == '\n') return KEY_ENTER;
    if (c == '.') return KEY_DOT;
    if (c == ',') return KEY_COMMA;
    return KEY_SPACE; // Fallback
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Usage: %s <delay_us> <text>\n", argv[0]);
        return 1;
    }

    int delay = atoi(argv[1]);
    char *text = argv[2];

    int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (fd < 0) {
        perror("Error opening /dev/uinput");
        return 1;
    }

    // Setup uinput device
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_EVBIT, EV_SYN);
    
    // Register keys
    for (int i = 0; i < 255; i++) ioctl(fd, UI_SET_KEYBIT, i);

    struct uinput_setup usetup;
    memset(&usetup, 0, sizeof(usetup));
    usetup.id.bustype = BUS_USB;
    usetup.id.vendor = 0x1234;
    usetup.id.product = 0x5678;
    strcpy(usetup.name, "Turbo Keystroke Injector");

    ioctl(fd, UI_DEV_SETUP, &usetup);
    ioctl(fd, UI_DEV_CREATE);

    // Wait for device creation
    usleep(100000); // 100ms

    // Type text
    for (int i = 0; text[i] != '\0'; i++) {
        int code = get_keycode(text[i]);
        
        emit(fd, EV_KEY, code, 1); // Press
        emit(fd, EV_SYN, SYN_REPORT, 0);
        
        if (delay > 0) usleep(delay);
        
        emit(fd, EV_KEY, code, 0); // Release
        emit(fd, EV_SYN, SYN_REPORT, 0);
        
        if (delay > 0) usleep(delay);
    }

    ioctl(fd, UI_DEV_DESTROY);
    close(fd);
    return 0;
}
