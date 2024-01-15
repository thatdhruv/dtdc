#!/usr/bin/env bash

clear
echo -ne "
\033[0;31m█████████████████████████████████████████████████████████████
█░░░░░░░░░░░░███░░░░░░░░░░░░░░█░░░░░░░░░░░░███░░░░░░░░░░░░░░█
█░░▄▀▄▀▄▀▄▀░░░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀░░░░█░░▄▀▄▀▄▀▄▀▄▀░░█
█░░▄▀░░░░▄▀▄▀░░█░░░░░░▄▀░░░░░░█░░▄▀░░░░▄▀▄▀░░█░░▄▀░░░░░░░░░░█
█░░▄▀░░██░░▄▀░░█████░░▄▀░░█████░░▄▀░░██░░▄▀░░█░░▄▀░░█████████
█░░▄▀░░██░░▄▀░░█████░░▄▀░░█████░░▄▀░░██░░▄▀░░█░░▄▀░░█████████
█░░▄▀░░██░░▄▀░░█████░░▄▀░░█████░░▄▀░░██░░▄▀░░█░░▄▀░░█████████
█░░▄▀░░██░░▄▀░░█████░░▄▀░░█████░░▄▀░░██░░▄▀░░█░░▄▀░░█████████
█░░▄▀░░██░░▄▀░░█████░░▄▀░░█████░░▄▀░░██░░▄▀░░█░░▄▀░░█████████
█░░▄▀░░░░▄▀▄▀░░█████░░▄▀░░█████░░▄▀░░░░▄▀▄▀░░█░░▄▀░░░░░░░░░░█
█░░▄▀▄▀▄▀▄▀░░░░█████░░▄▀░░█████░░▄▀▄▀▄▀▄▀░░░░█░░▄▀▄▀▄▀▄▀▄▀░░█
█░░░░░░░░░░░░███████░░░░░░█████░░░░░░░░░░░░███░░░░░░░░░░░░░░█
█████████████████████████████████████████████████████████████
[phase 0]\033[0m
"

source $DTDCDIR/setup.conf
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm --needed archlinux-keyring
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm --needed reflector rsync grub

echo -ne "
\033[0;31m[setting up $iso mirrors for optimal downloads]\033[0m
"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.old
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt &>/dev/null

echo -ne "
\033[0;31m[formatting disks]\033[0m
"
umount -A --recursive /mnt
sgdisk -Z ${DTDCDISK}
sgdisk -a 2048 -o ${DTDCDISK}
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DTDCDISK}
sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DTDCDISK}
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DTDCDISK}
if [[ ! -d "/sys/firmware/efi" ]] ; then
	sgdisk -A 1:set:2 ${DTDCDISK}
fi
partprobe ${DTDCDISK}


echo -ne "
\033[0;31m[creating filesystems]\033[0m
"
if [[ "${DTDCDISK}" =~ "nvme" ]] ; then
	partition2=${DTDCDISK}p2
	partition3=${DTDCDISK}p3
else
	partition2=${DTDCDISK}2
	partition3=${DTDCDISK}3
fi
mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
mkfs.ext4 -F -L ROOT ${partition3}
mount -t ext4 ${partition3} /mnt
mkdir -p /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/
if ! grep -qs '/mnt' /proc/mounts ; then
	clear
	echo -ne "\033[0;31m[disk is not mounted!]\033[0m"
	echo
	echo -ne "\033[0;31m[rebooting in 3s...]\033[0m" && sleep 1
	echo -ne "\033[0;31m[rebooting in 2s...]\033[0m" && sleep 1
	echo -ne "\033[0;31m[rebooting in 1s...]\033[0m" && sleep 1
	reboot now
fi

echo -ne "
\033[0;31m[installing the base system]\033[0m
"
pacstrap /mnt base base-devel linux linux-firmware archlinux-keyring sudo vim --noconfirm --needed
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${DTDCDIR} /mnt/root/dtdc
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
genfstab -L /mnt >> /mnt/etc/fstab

echo -ne "
\033[0;31m[installing bootloader]\033[0m
"
if [[ ! -d "/sys/firmware/efi" ]] ; then
	grub-install --boot-directory=/mnt/boot ${DTDCDISK}
else
	pacstrap /mnt efibootmgr --noconfirm --needed
fi

echo -ne "
\033[0;31m[checking if a swap file will be needed...]\033[0m
"
DTDCMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[ DTDCMEM -lt 8000000 ]] ; then
	mkdir -p /mnt/opt/swap
	dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
	chmod 600 /mnt/opt/swap/swapfile
	chown root /mnt/opt/swap/swapfile
	mkswap /mnt/opt/swap/swapfile
	swapon /mnt/opt/swap/swapfile
	echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab
fi

echo -ne "
\033[0;31m[ready for phase 1]\033[0m
"
