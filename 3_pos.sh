#!/usr/bin/env bash

echo -ne "
Phase 3 - Post Install
"
source ${HOME}/dtdc/setup.conf

if [[ -d "/sys/firmware/efi" ]] ; then
	grub-install --efi-directory=/boot ${DISK}
fi

echo -ne "
Creating GRUB menu
"
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "All set!"

echo -ne "
Enabling services
"
systemctl enable NetworkManager.service
echo "NetworkManager enabled"

echo -ne "
Cleaning up
"
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

sed -i "s/^$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL/#$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL/" /etc/sudoers

rm -r $HOME/dtdc
rm -r /home/$USERNAME/dtdc

cd $pwd
