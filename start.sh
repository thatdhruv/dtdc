#!/usr/bin/env bash

CONFIG_FILE=$DTDCDIR/setup.conf
if [ ! -f $CONFIG_FILE ] ; then
	touch -f $CONFIG_FILE
fi

set_option() {
	if grep -Eq "^${1}.*" $CONFIG_FILE ; then
		sed -i -e "/^${1}.*/d" $CONFIG_FILE
	fi
	echo "${1}=${2}" >> $CONFIG_FILE
}

select_option() {
	ESC=$(printf "\033")
	cursor_blink_on()	{ printf "$ESC[?25h" ; }
	cursor_blink_off()	{ printf "$ESC[?25l" ; }
	cursor_to()		{ printf "$ESC[$1;${2:-1}H" ; }
	print_option()		{ printf "$2   $1 " ; }
	print_selected()	{ printf "$2  $ESC[7m $1 $ESC[27m" ; }
	get_cursor_row()	{ IFS=';' read -sdR -p $'\E[6n' ROW COL ; echo ${ROW#*[}; }
	get_cursor_col()	{ IFS=';' read -sdR -p $'\E[6n' ROW COL ; echo ${COL#*[}; }
	key_input()		{
					local key
					IFS= read -rsn1 key 2>/dev/null >&2
					if [[ $key = "" ]] ; then echo enter ; fi ;
					if [[ $key = $'\x20' ]] ; then echo space ; fi ;
					if [[ $key = "k" ]] ; then echo up ; fi ;
					if [[ $key = "j" ]] ; then echo down ; fi ;
					if [[ $key = "h" ]] ; then echo left ; fi ;
					if [[ $key = "l" ]] ; then echo right ; fi ;
					if [[ $key = "a" ]] ; then echo all ; fi ;
					if [[ $key = "n" ]] ; then echo none ; fi ;
					if [[ $key = $'\x1b' ]] ; then
						read -rsn2 key
						if [[ $key = [A || $key = k ]] ; then echo up ; fi ;
						if [[ $key = [B || $key = j ]] ; then echo down ; fi ;
						if [[ $key = [C || $key = l ]] ; then echo right ; fi ;
						if [[ $key = [D || $key = h ]] ; then echo left ; fi ;
					fi
	}

	print_options_multicol() {
		local curr_col=$1
		local curr_row=$2
		local curr_idx=0

		local idx=0
		local row=0
		local col=0

		curr_idx=$(( $curr_col + $curr_row * $colmax ))

		for option in "${options[@]}" ; do
			row=$(( $idx/$colmax ))
			col=$(( $idx-$row*$colmax ))
			cursor_to $(( $startrow+$row+1 )) $(( $offset*$col+1 ))
			if [ $idx -eq $curr_idx ] ; then
				print_selected "$option"
			else
				print_option "$option"
			fi
			((idx++))
		done
	}

	for opt ; do printf "\n" ; done
	local return_value=$1
	local lastrow=`get_cursor_row`
	local lastcol=`get_cursor_col`
	local startrow=$(( $lastrow - $# ))
	local startcol=1
	local lines=$( tput lines )
	local cols=$( tput cols )
	local colmax=$2
	local offset=$(( $cols/$colmax ))
	local size=$4
	shift 4

	trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
	cursor_blink_off

	local active_row=0
	local active_col=0
	while true; do
		print_options_multicol $active_col $active_row
		case `key_input` in
			enter)	break;;
			up)	(( active_row-- ));
				if [ $active_row -lt 0 ] ; then active_row=0; fi;;
			down)	(( active_row++ ));
				if [ $active_row -ge $(( ${#options[@]}/$colmax )) ] ; then active_row=$(( ${#options[@]}/$colmax )); fi;;
			left)	(( active_col-- ));
				if [ $active_col -lt 0 ] ; then active_col=0; fi;;
			right)	(( active_col++ ));
				if [ $active_col -ge $colmax ] ; then active_col=$(( $colmax-1 )); fi;;
		esac
	done

	cursor_to $lastrow
	printf "\n"
	cursor_blink_on

	return $(( $active_col+$active_row*$colmax ))
}

timezone() {
	time_zone="$(curl --fail https://ipapi.co/timezone)"
	echo -ne "
	System detected your timezone to be '$time_zone' \n"
	echo -ne "Is this correct?
	"

	options=("Yes" "No")
	select_option $? 1 "${options[@]}"

	case ${options[$?]} in
		y|Y|yes|Yes|YES)
			echo "Timezone successfully set to ${time_zone}"
			set_option TIMEZONE $time_zone;;
		n|N|no|No|NO)
			read -p "Please enter your desired timezone (e.g. Europe/London): " new_timezone
			echo "Timezone successfully set to ${new_timezone}"
			set_option TIMEZONE $new_timezone;;
		*)
			echo "Invalid choice! Try again...";
			timezone;;
	esac
}

keymap() {
	echo -ne "
	Please select your keyboard layout
	"
	options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru sg ua uk)

	select_option $? 4 "${options[@]}"
	keymap=${options[$?]}

	echo -ne "Your keyboard layout is set to ${keymap} \n"
	set_option KEYMAP $keymap
}

drivessd() {
	echo -ne "
	Is this an SSD?
	"

	options=("Yes" "No")
	select_option $? 1 "${options[@]}"

	case ${options[$?]} in
		y|Y|yes|Yes|YES)
			set_option MOUNT_OPTIONS "noatime,compress=zstd,ssd,commit=120";;
		n|N|no|No|NO)
			set_option MOUNT_OPTIONS "noatime,compress=zstd,commit=120";;
		*)
			echo "Invalid choice! Try again..."
			drivessd;;
	esac
}

diskpart() {
	echo -ne "
	format warning
	"

	PS3='
	Select the disk to install on: '
	options=($(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}'))

	select_option $? 1 "${options[@]}"
	disk=${options[$?]%|*}

	echo -e "\n${disk%|*} selected \n"
	set_option DISK ${disk%|*}

	drivessd
}

userinfo() {
	read -p "Please enter username: " username
	set_option USERNAME ${username,,}
	while true ; do
		echo -ne "Please enter password: \n"
		read -s password

		echo -ne "Please confirm password: \n"
		read -s password2

		if [ "$password" = "$password2" ] ; then
			set_option PASSWORD $password
			break
		else
			echo -e "\nPasswords do not match! Try again...\n"
		fi
	done

	read -rep "Please enter hostname: " nameofmachine
	set_option NAME_OF_MACHINE $nameofmachine
}

aurhelper() {
	echo -ne "Do you want to install an AUR helper?\n"
	options=(yes no)
	select_option $? 1 "${options[@]}"
	case ${options[$?]} in
		y|Y|yes|Yes|YES)
			set_option AUR_HELPER "yay-git";;
		n|N|no|No|NO)
			set_option AUR_HELPER "none";;
		*)
			echo "Invalid choice! Try again..."
			aurhelper;;
	esac
}

desktopenv() {
	echo -ne "Please select your desired desktop environment:\n"
	options=(suckless server)
	select_option $? 4 "${options[@]}"
	desktop_env=${options[$?]}
	set_option DESKTOP_ENV $desktop_env
}

installtype() {
	echo -ne "Please select an installation type:\n"
	options=(FULL MINIMAL)
	select_option $?4 "${options[@]}"
	install_type=${options[$?]}
	set_option INSTALL_TYPE $install_type
}

clear
userinfo
clear
desktopenv
set_option INSTALL_TYPE MINIMAL
set_option AUR_HELPER NONE
if [[ ! $desktop_env == server ]] ; then
	clear
	aurhelper
	clear
	installtype
fi
clear
diskpart
clear
timezone
clear
keymap
