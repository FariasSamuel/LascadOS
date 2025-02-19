nasm -f bin bootloader.asm -o bootloader.bin
nasm -f bin kernel.asm -o kernel.bin
dd if=bootloader.bin of=disk.img conv=notrunc
dd if=kernel.bin of=disk.img seek=1 conv=notrunc
qemu-system-x86_64 -fda disk.img
