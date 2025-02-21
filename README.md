## Running the OS

```
nasm -f bin bootloader.asm -o bootloader.bin
nasm -f bin kernel.asm -o kernel.bin
dd if=bootloader.bin of=disk.img conv=notrunc
dd if=kernel.bin of=disk.img seek=1 conv=notrunc
qemu-system-x86_64 -fda disk.img
```
## Available commands

**help** - show all available commands\
**clear** - clear the screen\
**reboot** - restart the system\
**time** - show current time (doesn't work properly on qemu)\
**shutdown** - halts the cpu\
**mem** - show available memory

## To-do

- implement more (working) commands
- file management system
- application loading
- application (text editor in C)
