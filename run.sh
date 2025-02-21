# Step 1: Assemble the bootloader and kernel
echo "Assembling bootloader..."
nasm -f bin bootloader.asm -o bootloader.bin

echo "Assembling kernel..."
nasm -f bin kernel.asm -o kernel.bin

# Step 2: Compile and link the C program
echo "Compiling and linking C program..."
i686-elf-gcc -ffreestanding -m16 -nostdlib -c test.c -o test.o
i686-elf-ld -Ttext=0x2000 -o test.elf test.o
i686-elf-objcopy -O binary test.elf test.bin

# Step 3: Create the disk image and write files
echo "Creating disk image..."
dd if=/dev/zero of=disk.img bs=512 count=2880  # Create a blank 1.44MB floppy image

echo "Writing bootloader to sector 0..."
dd if=bootloader.bin of=disk.img bs=512 seek=0 conv=notrunc

echo "Writing kernel to sector 1..."
dd if=kernel.bin of=disk.img bs=512 seek=1 conv=notrunc

echo "Writing C program to sector 2..."
dd if=test.bin of=disk.img bs=512 seek=2 conv=notrunc

# Step 4: Run in QEMU
echo "Starting QEMU..."
qemu-system-x86_64 -fda disk.img