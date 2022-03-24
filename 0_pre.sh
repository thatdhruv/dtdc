#!/usr/bin/env bash

echo -ne "
Welcome to DTDC - DT's Distro Cloner!
"
source $DTDCDIR/setup.conf
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm archlinux-keyring
pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v18n
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm --needed reflector rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.old

echo -ne "
Setting up $iso mirrors for faster downloads
"
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt &>/dev/null

echo -ne "
Installing prerequisites
"
pacman -S --noconfirm --needed gptfdisk

echo -ne "
Formatting disk
"
umount -A --recursive /mnt
sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK}
sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK}
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK}
if [[ ! -d "/sys/firmware/efi" ]] ; then
	sgdisk -A 1:set:2 ${DISK}
fi
partprobe ${DISK}

echo -ne "
Creating filesystems
"
if [[ "${DISK}" =- "nvme" ]] ; then
	partition2=${DISK}p2
	partition3=${DISK}p3
else
	partition2=${DISK}2
	partition3=${DISK}3
fi

mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
mkfs.ext4 -L root ${partition3}
mount -t ext4 ${partition3} /mnt
mkdir -p /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot

if ! grep -qs '/mnt' /proc/mounts ; then
	echo "Drive unmounted! Cannot continue any further"
	echo "Rebooting in 3s..." && sleep 1
	echo "Rebooting in 2s..." && sleep 1
	echo "Rebooting in 1s..." && sleep 1
	reboot now
fi

echo -ne "
Installing the base system
"
pacstrap /mnt base base-devel linux linux-firmware vim sudo archlinux-keyring wget --noconfirm --needed
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${DTDCDIR} /mnt/root/dtdc
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

genfstab -L /mnt >> /mnt/etc/fstab
echo "
Generated /etc/fstab:
"
cat /mnt/etc/fstab

echo -ne "
Installing bootloader
"
if [[ ! -d "/sys/firmware/efi" ]] ; then
	grub-install --boot-directory=/mnt/boot ${DISK}
else
	pacstrap /mnt efibootmgr --noconfirm --needed
fi

echo -ne "
Checking if SWAP is needed
"
TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[ $TOTAL_MEM -lt 8000000 ]] ; then
	mkdir -p /mnt/opt/swap
	chattr +C /mnt/opt/swap
	dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
	chmod 600 /mnt/opt/swap/swapfile
	chown root /mnt/opt/swap/swapfile
	mkswap /mnt/opt/swap/swapfile
	swapon /mnt/opt/swap/swapfile
	echo "/opt/swap/swapfile    none    swap    sw      0       0" >> /mnt/etc/fstab
fi

echo -ne "
Getting ready for phase 1
"
