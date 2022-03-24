#!/usr/bin/env bash

echo -ne "
Phase 2 - User
"
source $HOME/dtdc/setup.conf

sed -n '/'$INSTALL_TYPE'/q;p' ~/dtdc/packs.txt | while read line
do
	if [[ ${line} == '--END OF MINIMAL INSTALL--' ]]
	then
		continue
	fi
	echo "installing ${line}"
	sudo pacman -S --noconfirm --needed ${line}
done

if [[ ! AUR_HELPER == none ]] ; then
	cd ~
	git clone "https://aur.archlinux.org/$AUR_HELPER.git"
	cd ~/$AUR_HELPER
	makepkg -si --noconfirm
fi

export PATH=$PATH:~/.local/bin

echo -ne "
Ready for phase 3
"
