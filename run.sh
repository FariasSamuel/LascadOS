# Step 1: Assemble the bootloader and kernel
echo "Assembling bootloader..."
nasm -f bin bootloader.asm -o bootloader.bin

echo "Assembling kernel..."
nasm -f bin kernel.asm -o kernel.bin

# Step 2: Compile and link the C program
echo "Compiling C program..."
ia16-elf-gcc -ffreestanding -m16 -nostdlib -c hi.c -o hi.o

echo "Linking the object file to create ELF binary..."
ia16-elf-ld -m elf_i386 -Ttext=0x2000 -o hi.elf hi.o

echo "Converting ELF to raw binary..."
objcopy -O binary hi.elf hi.bin

# Step 3: Create the disk image and write files
echo "Creating disk image..."
dd if=/dev/zero of=disk.img bs=512 count=2880  # Create a blank 1.44MB floppy image

echo "Writing bootloader to sector 0..."
dd if=bootloader.bin of=disk.img bs=512 seek=0 conv=notrunc

echo "Writing kernel to sector 1..."
dd if=kernel.bin of=disk.img bs=512 seek=1 conv=notrunc

echo "Writing C program to sector 2..."
dd if=hi.bin of=disk.img bs=512 seek=2 conv=notrunc

# Step 4: Run in QEMU
echo "Starting QEMU..."
qemu-system-x86_64 -fda disk.img