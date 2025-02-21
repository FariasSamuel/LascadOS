#include <stdint.h>

// Calls external functions defined on kernel
extern char read_key();
extern void read_string(char *buffer);
extern void print_char(char c, uint8_t row, uint8_t col);
extern void print_string();
extern int create_file(const char *filename, uint16_t size);

// Defines text buffer (80x25 screen)
#define SCREEN_WIDTH 80
#define SCREEN_HEIGHT 25
char text_buffer[SCREEN_HEIGHT][SCREEN_WIDTH];

// Cursor position
uint8_t cursor_row = 0;
uint8_t cursor_col = 0;

// Clear the text buffer
void clear_buffer() {
    for (int row = 0; row < SCREEN_HEIGHT; row++) {
        for (int col = 0; col < SCREEN_WIDTH; col++) {
            text_buffer[row][col] = ' ';
        }
    }
}

// Display the text buffer on the screen
void display_buffer() {
    for (int row = 0; row < SCREEN_HEIGHT; row++) {
        for (int col = 0; col < SCREEN_WIDTH; col++) {
            print_char(text_buffer[row][col], row, col);
        }
    }
}

// Handle keyboard input
void handle_input(char key) {
    switch (key) {
        case '\n': // Enter key (newline)
            cursor_row++;
            cursor_col = 0;
            if (cursor_row >= SCREEN_HEIGHT) {
                cursor_row = 0;  // Wrap to the top
            }
            break;
        case '\b': // Backspace
            if (cursor_col > 0) {
                cursor_col--;
                text_buffer[cursor_row][cursor_col] = ' ';
            }
            break;
        default: // Printable character
            if (cursor_col < SCREEN_WIDTH - 1) {
                text_buffer[cursor_row][cursor_col] = key;
                cursor_col++;
            }
            else {
                cursor_row++;
                cursor_col = 0;
                if (cursor_row >= SCREEN_HEIGHT) {
                    cursor_row = 0; // Wrap to the top if the screen is full
                }
                text_buffer[cursor_row][cursor_col] = key;
                cursor_col++;
            }
            break;
    }
}

// Saves the text buffer to a file
void save_file() {
    char filename[64]; // Buffer to store the filename

    // Prompt the user for a filename
    print_string("Enter filename: ");

    // Read the filename using the assembly function
    read_string(filename);

    // Calls the system call to create the file
    int process = create_file(filename, SCREEN_HEIGHT * SCREEN_WIDTH);
    if (process == 0) {
        print_string("File saved successfully.\n");
    } else {
        print_string("Error saving file.\n");
    }
}

// Text editor main function
void editor() {
    clear_buffer();
    display_buffer();

    while (1) {
        // Read a keypress
        char key = read_key();

        // Handle special keys (e.g., Escape to exit)
        if (key == 27) { // Escape key
            break;
        }

        // Handle input
        handle_input(key);

        // Refresh the screen
        display_buffer();
    }

    // Save the file before exiting
    save_file();
}