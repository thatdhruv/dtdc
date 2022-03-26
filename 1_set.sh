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
[phase 1]\033[0m
"

source $HOME/dtdc/setup.conf

echo -ne "
\033[0;31m[setting up network services]\033[0m
"
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm networkmanager grub git
systemctl enable --now NetworkManager

nc=$(grep -c ^processor /proc/cpuinfo)
echo -ne "
\033[0;31m[setting up makeflags and compression settings for "$nc" cores]\033[0m
"
DTDCTMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[ $DTDCTMEM -gt 8000000 ]] ; then
	sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"j$nc\"/g" /etc/makepkg.conf
	sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -z -T $nc -)/g" /etc/makepkg.conf
fi

echo -ne "
\033[0;31m[setting up locale]\033[0m
"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone ${DTDCTIME}
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-keymap us
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
ln -s /usr/share/zoneinfo/${DTDCTIME} /etc/localtime
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

echo -ne "
\033[0;31m[installing packages]\033[0m
"
while read line
do
	echo "[installing ${line}]"
	sudo pacman -S --noconfirm --needed ${line}
done < $DTDCDIR/packs.txt

echo -ne "
\033[0;31m[installing microcode]\033[0m
"
proc_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${proc_type} ; then
	echo "[installing intel microcode]"
	pacman -S --noconfirm --needed intel-ucode
	proc_ucode=intel-ucode.img
elif grep -E "AuthenticAMD" <<< ${proc_type} ; then
	echo "[installing amd microcode]"
	pacman -S --noconfirm --needed amd-ucode
	proc_ucode=amd-ucode.img
fi

echo -ne "
\033[0;31m[installing graphics drivers]\033[0m
"
gpu=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu} ; then
	pacman -S --noconfirm --needed nvidia
	nvidia-xconfig
elif lspci | grep 'VGA' | grep -E "Radeon|AMD" ; then
	pacman -S --noconfirm --needed xf86-video-amdgpu
elif grep -E "Intel Graphics Controller" <<< ${gpu} ; then
	pacman -S --noconfirm --needed xf86-video-intel
elif grep -E "Intel Corporation UHD" <<< ${gpu} ; then
	pacman -S --noconfirm --needed xf86-video-intel
fi

echo -ne "
\033[0;31m[setting up user]\033[0m
"
if [ $(whoami) = "root" ] ; then
	useradd -m -G wheel -s /bin/bash $DTDCUSER
	echo "[successfully added user $DTDCUSER]"
	echo "$DTDCUSER|$DTDCPASS" | chpasswd
	echo "[successfully set password for $DTDCUSER]"
	echo "$DTDCUSER ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
	cp -R $HOME/dtdc /home/$DTDCUSER/
	chown -R $DTDCUSER: /home/$DTDCUSER/dtdc
	echo "[dtdc copied to home directory]"
	echo $DTDCHOST > /etc/hostname
else
	echo "You already seem to be a user. Proceeding with phase 2..."
fi

echo -ne "
\033[0;31m[ready for phase 2]\033[0m
"
