// Compile with gcc `gcc -o zAddUser zAddUser.c` 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include <pwd.h>

void check_root() {
    if (geteuid() != 0) {
        fprintf(stderr, "This program must be run as root. Please use sudo.\n");
        exit(EXIT_FAILURE);
    }
}

void capitalise_first_letter(char *str) {
    if (str != NULL && strlen(str) > 0) {
        str[0] = toupper(str[0]);
    }
}

int user_exists(const char *username) {
    return getpwnam(username) != NULL;
}

int main() {
    char username[100];
    char capitalised_username[100];
    char command[256];

    // Check if running as root
    check_root();

    // Get username input
    printf("Enter a username (lowercase only): ");
    if (scanf("%99s", username) != 1) {
        fprintf(stderr, "Failed to read username.\n");
        exit(EXIT_FAILURE);
    }

    // Check if user already exists
    if (user_exists(username)) {
        fprintf(stderr, "User %s already exists.\n", username);
        exit(EXIT_FAILURE);
    }

    // Copy username and capitalise the first letter for the password
    strcpy(capitalised_username, username);
    capitalise_first_letter(capitalised_username);

    // Create the user with a home directory and bash shell
    snprintf(command, sizeof(command), "useradd -m -s /bin/bash %s", username);
    if (system(command) != 0) {
        fprintf(stderr, "Failed to create user.\n");
        exit(EXIT_FAILURE);
    }

    // Set the password with capitalized first letter
    snprintf(command, sizeof(command), "echo \"%s:%s1!\" | chpasswd", username, capitalised_username);
    if (system(command) != 0) {
        fprintf(stderr, "Failed to set password.\n");
        exit(EXIT_FAILURE);
    }

    // Create .ssh directory in the user's home directory
    snprintf(command, sizeof(command), "mkdir -p /home/%s/.ssh", username);
    if (system(command) != 0) {
        fprintf(stderr, "Failed to create .ssh directory.\n");
        exit(EXIT_FAILURE);
    }

    // Set permissions on the .ssh directory
    snprintf(command, sizeof(command), "chown %s:%s /home/%s/.ssh && chmod 700 /home/%s/.ssh", username, username, username, username);
    if (system(command) != 0) {
        fprintf(stderr, "Failed to set permissions on .ssh directory.\n");
        exit(EXIT_FAILURE);
    }

    // Create an empty authorized_keys file
    snprintf(command, sizeof(command), "touch /home/%s/.ssh/authorized_keys", username);
    if (system(command) != 0) {
        fprintf(stderr, "Failed to create authorized_keys file.\n");
        exit(EXIT_FAILURE);
    }

    // Set permissions on the authorized_keys file
    snprintf(command, sizeof(command), "chown %s:%s /home/%s/.ssh/authorized_keys && chmod 600 /home/%s/.ssh/authorized_keys", username, username, username, username);
    if (system(command) != 0) {
        fprintf(stderr, "Failed to set permissions on authorized_keys file.\n");
        exit(EXIT_FAILURE);
    }

    printf("User %s created, password set to %s1!, .ssh directory and authorized_keys file created with correct permissions.\n", username, capitalised_username);

    return 0;
}
