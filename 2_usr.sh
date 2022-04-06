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
[phase 2]\033[0m
"

source $HOME/dtdc/setup.conf

echo -ne "
\033[0;31m[setting up graphical environment]\033[0m
"
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
git clone https://aur.archlinux.org/ttf-yosemite-san-francisco-font-git.git
cd ttf-yosemite-san-francisco-font-git
makepkg -si
cd ~
git clone https://github.com/thatdhruv/dotfiles
cp -r dotfiles/. .
rm -rf .sources dotfiles .git README.md

echo -ne "
\033[0;31m[downloading wallpapers]\033[0m
"
git clone https://gitlab.com/dwt1/wallpapers

echo -ne "
\033[0;31m[ready for phase 3]\033[0m
"
