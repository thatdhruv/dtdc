#!/usr/bin/env bash

config=$DTDCDIR/setup.conf
if [ ! -f $config ] ; then
	touch -f $config
fi

setOption() {
	if grep -Eq "^${1}.*" $config ; then
		sed -i -e "/^${1}.*/d" $config
	fi
	echo "${1}=${2}" >> $config
}

logo() {
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
[welcome to dtdc - dt's distro cloner!]\033[0m
	"
	echo
}

userInfo() {
	read -p "Please enter your username: " dtdcUser
	setOption DTDCUSER ${dtdcUser,,}
	while true ; do
		echo -ne 'Please enter your password: '
		read -s dtdcPass1
		echo -ne '\nPlease confirm your password: '
		read -s dtdcPass2
		if [ "$dtdcPass1" = "$dtdcPass2" ] ; then
			setOption DTDCPASS $dtdcPass1
			break
		else
			echo -e '\nPasswords do not match! Please try again...\n'
		fi
	done
	echo
	read -rep 'Please enter your hostname: ' dtdcHost
	setOption DTDCHOST $dtdcHost
}

diskInfo() {
	echo -ne 'Select the disk to install on:\n'
	lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2" - "$3}'
	echo
	read -p "Please enter full path to the disk (e.g. /dev/sda): " dtdcDisk
	echo
	echo -ne "${dtdcDisk} selected"
	setOption DTDCDISK ${dtdcDisk}
}


timezone() {
	dtdcTimezone="$(curl --fail https://ipapi.co/timezone)"
	echo -ne "Your timezone seems to be '${dtdcTimezone}'"
	echo
	read -p "Is this correct? (y/n): " tz
	if [[ $tz == 'y' ]] || [[ $tz == 'Y' ]] ; then
		echo "Timezone set to ${dtdcTimezone}"
		setOption DTDCTIME $dtdcTimezone
	elif [[ $tz == 'n' ]] || [[ $tz == 'N' ]] ; then
		echo
		read -p "Please enter your desired timezone (e.g. Europe/London): " newTimezone
		echo "Timezone set to ${newTimezone}"
		setOption DTDCTIME $newTimezone
	else
		echo -ne '\nInvalid choice! Please try again...'
		timezone
	fi
}

clear
logo
userInfo
clear
logo
diskInfo
clear
logo
timezone
