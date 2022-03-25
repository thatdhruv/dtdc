#!/usr/bin/env bash

echo -ne "
Phase 2 - User
"
source $HOME/dtdc/setup.conf

if [[ ! AUR_HELPER == none ]] ; then
	cd ~
	git clone "https://aur.archlinux.org/$AUR_HELPER.git"
	cd ~/$AUR_HELPER
	makepkg -si --noconfirm
fi

export PATH=$PATH:~/.local/bin

if [[ $INSTALL_TYPE == "full" ]] ; then
	cd ~
	mkdir .sources
	cd .sources
	
	git clone https://github.com/thatdhruv/dwm
	cd dwm
	make
	sudo make install
	cd ..
	
	git clone https://github.com/thatdhruv/dmenu
	cd dmenu
	make
	sudo make install
	cd ..
	
	git clone https://github.com/thatdhruv/st
	cd st
	make
	sudo make install
	cd ..
	
	git clone https://github.com/thatdhruv/slstatus
	cd slstatus
	make
	sudo make install
	cd ..
	
	git clone https://github.com/thatdhruv/dotfiles
	cd ~
	cp -R dotfiles/* .
	
	git clone https://gitlab.com/dwt1/wallpapers
	
	rm -r .sources dotfiles
fi

echo -ne "
Ready for phase 3
"
