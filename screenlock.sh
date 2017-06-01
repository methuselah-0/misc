#!/bin/bash -x
#  You need to install alock, cmatrix, xdotool, xscreensaver, urxvt,
#+ put this file in your path, e.g. ~/bin/screenlock.sh and finally
#+ add the following to crontab:
#+ */3 * * * * DISPLAY=:0 screenlock.sh

if !(pgrep alock) && xscreensaver-command -time | grep -q 'screen blanked' ; then
#if true ; then
     # Toggle xmobar visibility
    xdotool key super+shift+b

    # Disable VT-switching
    setxkbmap -option srvrkeys:none

    # The xscreensaver blanking hangs the cmatrix program.
    blankprotect(){
	sleep 3
	while pgrep alock ; do xscreensaver-command -deactivate && sleep 5 ; done
	echo "hej"
	pkill cmatrix
    }
    blankprotect &

    # Lock and start cmatrix
    sudo -HPE -u user1 /bin/bash -c alock -b none -c blank & urxvt -e cmatrix
    
    # Reset
    xdotool key super+b
    setxkbmap -option ''
    xmodmap /home/user1/.Xmodmap &
fi
