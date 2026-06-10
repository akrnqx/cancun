#!/bin/bash
set -e

zig build -Dlog_level=debug

mkdir -p mnt/EFI/BOOT

# use upper case, to make fat have an easier time
cp zig-out/bin/cancun.efi mnt/EFI/BOOT/BOOTX64.EFI
cp zig-out/bin/cab.elf mnt/CAB.ELF

qemu-system-x86_64 \
	-bios /usr/share/edk2/x64/OVMF.4m.fd \
	-drive file=fat:rw:mnt,format=raw \
	-cpu host,vmx=on \
	-enable-kvm \
	-net none \
	-m 256M \
	-serial mon:stdio \
	-s -S
