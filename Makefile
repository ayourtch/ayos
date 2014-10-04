all:
	nasm -o build/pure64.sys -I ./pure64/src/ pure64/src/pure64.asm 
	(cd kernel; make)
	nasm -o build/fat32boot.bin pure64/bootsector/fat32boot.asm
	dd if=/dev/zero of=build/disk.img bs=1024 count=65536
	mkdosfs -F 32 build/disk.img
	dd if=build/fat32boot.bin of=build/disk.img bs=1 count=452 seek=60 skip=60 conv=notrunc
	sudo mount -o loop build/disk.img build/mnt
	sudo cp build/pure64.sys build/mnt/
	sudo cp kernel/kernel64.sys build/mnt/
	sudo umount build/mnt
	kvm -monitor stdio -hda build/disk.img -gdb tcp::1234 -vnc [::]:1
	# kvm -hda build/disk.img -vnc [::]:1
clean:
	(cd kernel; make clean)
	rm -f build/* || true
disasm:
	objdump -D -b binary -m i386:x86-64 kernel/kernel64.sys  | less

