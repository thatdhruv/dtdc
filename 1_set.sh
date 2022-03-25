#!/usr/bin/env bash

echo -ne "
Phase 1 - Setup
"
source $HOME/dtdc/setup.conf

echo -ne "
Network setup
"
pacman -S --noconfirm --needed networkmanager dhclient
systemctl enable --now NetworkManager

echo -ne "
Setting up mirrors for optimal download
"
pacman -S --noconfirm --needed curl
pacman -S --noconfirm --needed reflector grub git
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.old

cores=$(grep -c ^processor /proc/cpuinfo)

echo -ne "
Your system has " $cores " cores. Applying necessary modifications to the MAFEFLAGS and compression settings.
"
TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[ $TOTAL_MEM -gt 8000000 ]] ; then
	sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$cores\"/g" /etc/makepkg.conf
	sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $cores -z -)/g" /etc/makepkg.conf
fi

echo -ne "
Setting language and locale
"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone ${TIMEZONE}
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
localectl --no-ask-password set-keymap ${KEYMAP}

sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL' /etc/sudoers

sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed

echo -ne "
Installing base system
"
if [[ ! $INSTALL_TYPE == minimal ]] ; then
	sed -n '/'$INSTALL_TYPE'/q;p' $HOME/dtdc/packs.txt | while read line
do
	if [[ ${line} == '--END OF MINIMAL INSTALL--' ]] ; then
		continue
	fi
	echo "installing ${line}"
	sudo pacman -S --noconfirm --needed ${line}
done
fi

echo -ne "
Installing microcode
"
proc_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${proc_type} ; then
	echo "Installing Intel microcode"
	pacman -S --noconfirm --needed intel-ucode
	proc_ucode=intel-ucode.img
elif grep -E "AuthenticAMD" <<< ${proc_type} ; then
	echo "Installing AMD microcode"
	pacman -S --noconfirm --needed amd-ucode
	proc_ucode=amd-ucode.img
fi

gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type} ; then
	pacman -S --noconfirm --needed nvidia
	nvidia-xconfig
elif lspci | grep 'VGA' | grep -E "Radeon|AMD" ; then
	pacman -S --noconfirm --needed xf86-video-amdgpu
elif grep -E "Integrated Graphics Controller" <<< ${gpu_type} ; then
	pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-utils lib32-mesa
elif grep -E "Intel Corporation UHD" <<< ${gpu_type} ; then
	pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-utils lib32-mesa
fi

if ! source $HOME/dtdc/setup.conf ; then
	while true
	do
		read -p "Please enter username: " username
		if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]
		then
			break
		fi
		echo "Invalid username!"
	done

	echo "username=${username,,}" >> ${HOME}/dtdc/setup.conf
	read -p "Please enter password: " password
	echo "password=${password,,}" >> ${HOME}/dtdc/setup.conf

	while true
	do
		read -p "Please enter machine name: " name_of_machine
		if [[ "${name_of_machine,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]
		then
			break
		fi
		read -p "Invalid hostname format. Do you still want to save it? (y/n)" force
		if [[ "${force,,}" = "y" ]]
		then
			break
		fi
	done

	echo "NAME_OF_MACHINE=${name_of_machine,,}" >> ${HOME}/dtdc/setup.conf
fi

echo -ne "
Adding user
"
if [ $(whoami) = "root" ] ; then
	groupadd libvirt
	useradd -m -G wheel,libvirt -s /bin/bash $USERNAME
	echo "User $USERNAME created, home directory created, added to groups wheel and libvirt, default shell set to /bin/bash"

	echo "$USERNAME:$PASSWORD" | chpasswd
	echo "Password for $USERNAME has been set successfully"

	cp -R $HOME/dtdc /home/$USERNAME/
	chown -R $USERNAME: /home/$USERNAME/dtdc
	echo "dtdc copied to home directory"

	echo $NAME_OF_MACHINE > /etc/hostname
else
	echo "You already seem to be a user. Proceeding with AUR installs"
fi

echo -ne "
Ready for phase 2
"
