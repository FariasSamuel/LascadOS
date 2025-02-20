i686-elf-gcc -ffreestanding -m16 -nostdlib -c test.c -o test.o
i686-elf-ld -Ttext=0x2000 -o test.elf test.o
i686-elf-objcopy -O binary test.elf test.bin

nasm -f bin bootloader.asm -o bootloader.bin
nasm -f bin kernel.asm -o kernel.bin

dd if=bootloader.bin of=disk.img bs=512 seek=0 conv=notrunc
dd if=kernel.bin of=disk.img bs=512 seek=1 conv=notrunc
dd if=test.bin of=disk.img bs=512 seek=2 conv=notrunc

qemu-system-x86_64 -fda disk.img