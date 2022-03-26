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
[phase 3]\033[0m
"
source ${HOME}/dtdc/setup.conf

if [[ -d "/sys/firmware/efi" ]] ; then
	grub-install --efi-directory=/boot ${DISK}
fi

clear
echo -ne "
\033[0;31m[creating grub configuration]\033[0m
"
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "All set!"

clear
echo -ne "
\033[0;31m[enabling services]\033[0m
"
systemctl enable NetworkManager.service
echo "NetworkManager enabled"

clear
echo -ne "
\033[0;31m[cleaning up]\033[0m
"
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

sed -i "s/^$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL/#$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL/" /etc/sudoers

rm -r $HOME/dtdc
rm -r /home/$USERNAME/dtdc

cd $pwd
