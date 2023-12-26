#!/bin/sh

pacman -Sy --noconfirm --needed git
git clone https://github.com/thatdhruv/dtdc
cd dtdc
./dtdc.sh
