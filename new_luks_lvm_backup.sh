#!/bin/bash

#  Copyright © 2017 David Larsson <david.larsson@selfhosted.xyz>
#
#  new_luks_lvm_backup.sh is free software: you can redistribute it and/or
#+ modify it under the terms of the GNU General Public License as
#+ published by the Free Software Foundation, either version 3 of the
#+ License, or (at your option) any later version.
#  
#  new_luks_lvm_backup.sh is distributed in the hope that it will be
#+ useful, but WITHOUT ANY WARRANTY; without even the implied warranty
#+ of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#+ General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#+ along with new_luks_lvm_backup.sh.  If not, see
#+ <http://www.gnu.org/licenses/>.

source bash-scripts

: <<EOT
Script procedure:
  * Read info from the mounted partitions to variables.
  * Build partition table on the target same as source with parted. 
  * Unmount /boot partitions, then partclone those to target.
  * Change uuid on all target partitions with uuidgen and tune2fs.
  * Mount /boot target partitions.
  * sed /boot/grub/grub.cfg on the target which contains the uuid of the source /boot partition, e.g. /dev/sda2, with the new UUID of the target /boot partition such as /dev/sdb2.
  * Remount /boot source partitions.
  * On target:
    * Create LVM physical vol with pvcreate
    * Differently named VG with vgcreate
    * LV's named same as source with lvcreate and with same amount of logical extents as source.
  * Rsync source LV's to target LV's: /home to home LV, /var to the var LV etc, then copy most of the rest (not /dev /boot etc.) to the root LV.
  * Special case of /boot on root partition, do not exclude /boot for the root LV copy.
  * sed /etc/fstab with the new uuid and vg names. For each identified LV; sed replace all UUID's and VG-LV names covering both cases of referencing the partitions in the fstab. Note: grep fstab entries carefully, because VG name and LV names sometimes have more than 1 dash in their full name (e.g. Debian).
  * cat a cronjob for rsync command.

**rsync notes**
[[https://unix.stackexchange.com/questions/96523/how-can-a-filesystem-be-copied-exactly-as-is#96529|source]]\\
Copy with (as root):
  rsync -axXSAH <source> <destination>
Explanation:
  * -S Copy over sparse files.
  * -x only copy within the filesystem, and not files mounted from another filesystem.
  * -AH means preserve any link structure and x-attrs in the target folder while copying.
  * -a means archive and preserves time, ownership and permissions already.  
EOT

f_do_Review_Source_Device_Info() { # -> IO
cat <<EOT
    bootsourcedev: $BOOTSP
    bootfs: $BOOTFS
    bootsize: $BOOTSIZE
    efisourcedev: $EFISP
    efifs: $EFIFS
    efisize: $EFISIZE
    rootfs: $ROOTFS
EOT
    read -p "Please review the discovered source device information. Is it as expected? (Y/n)" ;
    if [ -z $REPLY ] || [ $REPLY != "y" ] ; then echo "Continuing..."
    elif [ $REPLY == "y" ] ; then
	echo "Press Ctrl+C to cancel."
    else exit1 ; fi
}

f_do_Diskwipe() { # Dev -> IO
    read -p "Are you sure you want to wipe $1? (y/N)" ;
    if [ -z $REPLY ] || [ $REPLY != y ] ; then echo "Press Ctrl+C to cancel."
    elif [ $REPLY == "y" ] ; then
	echo "Wiping: $1"
	wipefs --all /dev/${1}
	head -c 3145728 /dev/urandom > /dev/${$1}; sync
    else exit 1 ; fi
}

#  Interactive primary partitioning
f_do_Primary_Partitioning() { # Dev -> Int
    #  Suggest partitioning table
    f_get_SCHEME_for() { # Dev -> GVAR, -> {1-3}
	if [[ -n ${BOOTSP} ]] && [[ -n ${EFISP} ]] ; then echo "3" ;
	elif [[ -n ${BOOTSP} ]] && [[ -z ${EFISP} ]] ; then echo "2" ; 
	else echo "1" ; fi
    }

    f_set_VARS() {
	if [ $1 = "3" ] ; then
	    #  FIXME: Assuming that /boot is in MiB and not GiB.
	    bootsize=`echo ${BOOTSIZE} | sed 's/MiB//'`
	    efisize=`echo ${EFISIZE} | sed 's/MiB//'`
	    TOTBSIZE=$(( ${bootsize} + ${efisize} ))MiB
	    TPEFI="${TDEV}1"
	    TPBOOT="${TDEV}2"
	    TPROOT="${TDEV}3"
	elif [ $1 == "2" ] ; then
    	    TPBOOT=${TDEV}1
	    TPROOT=${TDEV}2
	elif [ $1 = "1" ] ; then
	    TPROOT=${TDEV}1
	else echo "error f_set_VARS got bad input" ; exit 1 ; fi
    }
    
    f_get_Approve_SCHEME() { # {1-3} -> BOOL
	if [ ${1} == "3" ] ; then
cat <<EOT
Suggested partitioning:
    Target device: ${TDEV}
    Efi partition on: ${TPEFI}, size: ${EFISIZE}
    Boot partition on: ${TPBOOT}, size ${BOOTSIZE}
    /boot total size, i.e. boot plus efi: $TOTBSIZE
    Root partition on: ${TPROOT}, size total-${TOTBSIZE}
EOT
        elif [ ${1} == "2" ] ; then
	    echo "Boot partition on target: $TPBOOT"
	    echo "Root partition on target: $TPROOT"
        elif [ ${1} == "1" ] ; then
	    echo "Root partition on target: $TPROOT"
	    echo "Your setup implies you're booting from flashrom or similar. Your target root will be encrypted and no separate /boot partition will be created."
	else
	    echo "review_scheme function was not called with a valid argument"
	    exit 1
	fi
        read -p "Please review the target partitioning scheme and make sure it corresponds to source but targets a different device. Would you like to apply this partitioning scheme? (y/N)"
	if [ -z $REPLY ] || [ $REPLY != "y" ] ; then
	     return 1 # return FALSE
	elif [ $REPLY == "y" ] ; then
	    return 0 # return TRUE
	else
	    exit 1 # exit with ERROR
	fi
    }
    
    f_do_Apply() { # {1-3} -> IO
	#apt-get install partclone parted
	#f_diskwipe ${TDEV}
	#  Partclone reference: http://partclone.org/usage/partclone.php
	if [ $1 == "3" ] ; then
	    
	    #  Create 1 boot partition and 1 root partition
	    parted -a optimal --script /dev/${TDEV} \
		   mklabel gpt \
		   mkpart ESP ${EFIFS} 0MiB ${EFISIZE} \
		   set 1 boot on \
		   mkpart primary ${BOOTFS} ${EFISIZE} ${TOTBSIZE} \
		   mkpart primary ${TOTBSIZE} 100%

	    #  umount /boot and /boot/efi partitions to be on the safe side before cloning:
	    umount /dev/${BOOTSP} && umount /dev/${EFISP}
	    
	    #  Clone unencrypted boot partitions with partclone.
	    partclone.${BOOTFS} -c -s /dev/${BOOTSP} -o - | partclone.${BOOTFS} -r -s - -o /dev/${TPBOOT}
	    partclone.${EFIFS} -c -s /dev/${EFISP} -o - | partclone.${EFIFS} -r -s - -o /dev/${TPEFI}

	    #  Change target boot partition uuid to allow mounting of target boot partitions.
	    #  (use reiserfstune instead if you use reiserfs)
	    apt-get install uuid e2fslibs
	    newbootuuid=`uuid -v4`
	    newefiuuid=`uuid -v4`
	    tune2fs /dev/${TPBOOT} -U ${newbootuuid}
	    tune2fs /dev/${TPEFI} -U ${newefiuuid}

	    #  mount target boot partitions.
	    mkdir -p /mnt/${TPBOOT} && mount /dev/${TPBOOT} /mnt/${TPBOOT}
	    mkdir -p /mnt/${TPEFI} && mount /dev/${TPEFI} /mnt/${TPEFI}

	    #  edit the boot partition uuid entry in the target boot partition file /boot/grub/grub.cfg from source uuid to target uuid.
	    sourcebootuuid=`blkid /dev/${TPBOOT} | awk ' { print $2 } ' | cut -c 7-42`
	    sed -i 's/${sourcebootuuid}/${newbootuuid}/g' /mnt/${TPBOOT}

	elif [ $1 == "2" ] ; then
	    #  Create 1 boot partition and 1 root partition	    
	    #  To be on the safe side before cloning:
	    umount /dev/${BOOTSP} && umount /dev/${BOOTSP}

	    #  Clone unencrypted boot partitions.
	    parted -a optimal --script /dev/${TDEV} mklabel gpt mkpart primary 0.0 ${BOOTSIZE} mkpart primary ${ROOTFS} ${BOOTSIZE} 100%
	    partclone.${BOOTFS} -c -s /dev/${BOOTSP} -o - | partclone.${BOOTFS} -r -s - -o /dev/${TPBOOT}

	    #  Change target boot partition uuid to allow mounting of target boot partition.
	    apt-get install uuid e2fslibs	    
	    newbootuuid=`uuid -v4`
	    tune2fs /dev/${TPBOOT} -U ${newbootuuid}	    

	elif [ $1 == "1" ] ; then
    	    #  Create 1 partition.
	    parted -a optimal --script /dev/${TDEV} mklabel gpt mkpart primary ${ROOTFS} 0% 100%
	else exit 1 ; fi
    }
    local SCHEME=`f_get_SCHEME_for $1`
    f_set_VARS $SCHEME
    if f_get_approve_SCHEME ${SCHEME} ; then
	f_do_apply $SCHEME
    else echo "Press Ctrl+c to manually exit" ; fi
}

#  Encrypts given partition with strong settings.
f_do_Luks-Encrypt() {
    read -p "Would you like to encrypt the target root partition: ${1} (y/N)"
    if [ -z $REPLY ] || [ $REPLY != "y" ] ; then echo "Press Ctrl+C to cancel."
    elif [ $REPLY == "y" ] ; then
	echo "I would almost have fucking done it!"
	#cryptsetup -v --cipher serpent-xts-plain64 --key-size 512 --hash whirlpool --iter-time 60 --use-random --verify-passphrase luksFormat /dev/${1}
	#<YES>
	#<enter secure passphrase>
	#<enter secure passphrase again>
    else exit 1 ; fi 
}

#  Reads system LVM setup and creates a "semi-clone" - new uuid and VG-name, on given target partition.
f_do_Clone_Lvm()
{   # String , String -> IO
    f_get_Scheme()
    { # -> [(String,String)]
	local -A lv_size
	for lv in $(lvdisplay | grep "LV Name" | cut -c 26-100) ; do
	    #CURRENT_LE=`lvdisplay | grep $lv -C 10 | grep "Current LE" | cut -c 26-100`
	    size=`lvdisplay | grep "$lv" -C 10 | grep "LV Size" | cut -c 26-100 | sed "s/B\ .*/B/" | sed "s/\ //"`
	    lv_size[$lv]=$size
	#echo "current_le: $CURRENT_LE"
	#echo "new_size: $NEW_SIZE"
	done
	declare -p lv_size | f_get_Key-Val_To_Key-Val-String
    }
    local scheme=`f_get_Scheme`    
    f_get_Review()
    { # String , [(String,String)] -> Bool
        local -n arr=$2
cat <<EOT
    The following LVM scheme is suggested for your target root partition ${1}, please review:
    Create Physical Volume on /dev/mapper/${1}_crypt
    Create Volume Group vg${R}
    Logical volumes to be created:
EOT
	for lv in "${!arr[@]}" ; do
	echo "lvcreate -n $lv -l $CURRENT_LE vg${R}"
    }
    f_do_Apply()
    { # String , [(String,String)] -> IO
	local R=`echo "$RANDOM" | cut -c 1-3`
	pvcreate /dev/mapper/${1}_crypt
	vgcreate vg${R} /dev/mapper/${1}_crypt
	for lv in $2 ; do
	    lvcreate -n $lv -l $CURRENT_LE vg${R}
	done
	#mkdir -p /mnt/target_root_partition
	#mount 
    }
    f_get_Scheme "$1" "$2"
}


main() {
    #  Non-sourcable Source Device Variables.
    #  Inherited only by functions within the script.
    #  Also, non-editable by all of main's subfunctions.
    SDEV=$1
    TDEV=$2
    BOOTSP=`mount | grep "on /boot "  | awk ' { print $1 } '`
    BOOTFS=`df -T | egrep "/boot" | grep -v efi | cut -c 30-100 | sed "s/\ .*//"`
    BOOTSIZE=`df -Th | grep /boot | grep -v efi | cut -c 40-100 | sed "s/M\ .*/MiB/" | sed "s/G\ .*/GiB/"`
    EFISP=`mount | grep "on /boot/efi "  | awk ' { print $1 } '`
    EFIFS=`df -T | grep efi | cut -c 30-100 | sed "s/\ .*//"`
    EFISIZE=`df -Th | grep efi | cut -c 40-100 | sed "s/M\ .*/MiB/" | sed "s/G\ .*/GiB/"`
    ROOTFS=`mount | grep "on / " | awk ' { print $5 } '`
    f_do_review_source_device_info $1 # U-IO
    f_do_primary_partitioning $2 # U-IO
    f_do_luks-encrypt ${TPROOT} # U-IO
    f_do_clone_lvm ${TPROOT} # U-IO
    #cryptsetup luksOpen /dev/${TPROOT} ${TPROOT}_crypt
}

sourcable_var="this is a global var imported from new_luks_lvm_backup"

if [ "${1}" != "--source-only" ] ; then
    if [ -z $1 ] || [ -z $2 ] ; then
	echo "You must provide source and target device (not partitions) as 1st and 2nd argument respectively, e.g ./new_luks_lvm_backup.sh sda sdb"
	exit 1
    fi
    if [[ `id -u` -ne 0 ]] ; then
	echo 'Please run me as root or "sudo ./new_luks_lvm_backup.sh sdX(source) sdY(target)"'
	exit 1
    fi
    #  $@ evaluates to all of the arguments passed to the function or script as individual strings.
    main "${@}"
fi

#  Create /boot on target
#  dd if=${BOOTSP} of=/dev/${TDEV}1 bs=4M
#  fsck.${BOOTFS} -f -y /dev/${TDEV}1
#  resize2fs /dev/${TDEV}1

#  old
#  df -T | egrep "/boot" | grep -v efi | cut -c 30-100 | sed "s/\ .*//"
#  dd if=/dev/mapper/$lv of=/dev/vg${R}/$lv bs=4M
#  lvresize /dev/vg${R}/$lv -L $NEW_SIZE
#  fsck.ext4 -f -y /dev/vg${R}/$lv
#  resize2fs /dev/vg${R}/$lv
