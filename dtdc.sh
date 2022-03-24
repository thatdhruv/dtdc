#!/bin/bash

set -a
DTDCDIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
set +a

echo -ne "
welcome to dtdc
"

( bash $DTDCDIR/start.sh )|& tee start.log
source $DTDCDIR/setup.conf
( bash $DTDCDIR/0_pre.sh )|& tee 0_pre.log
( arch-chroot /mnt $HOME/dtdc/1_set.sh )|& tee 1_set.log
if [[ ! $DESKTOP_ENV == server ]] ; then
	( arch-chroot /mnt /usr/bin/runuser -u $USERNAME -- /home/$USERNAME/dtdc/2_usr.sh )|& tee 2_usr.log
fi
( arch-chroot /mnt $HOME/dtdc/3_pos.sh )|& tee 3_pos.log
cp -v *.log /mnt/home/$USERNAME

echo -ne "
please eject media and reboot
"
