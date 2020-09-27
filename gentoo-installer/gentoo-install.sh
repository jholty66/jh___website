#!/bin/bash
### About
# This script does not show how to partitino the disks, as that varies
# between different computers and user preferences

#### What this script does
# This script performs a minimal install of Gentoo Linux on BTRFS file
# system, with System-D and GenKernel automatically without any user
# input once it is executed.

# I choose not to use the latest Stage 3 tarball and kernel versions, as
# these have been tested and have no errors. Using the latest versions
# has the potential of creating an extra point of failure during the
# installation process.

# Similarly, Genkernel is used to both avoid manually configuring the
# kernel and to narror the points of failure when booting in the system
# for the first time. Once the system has been booted successfully,
# Genkernel can be replaced with a customized kernel configuration.

# This does not partition or format the disks, that is left to the user
# or done with the script "partition-disks.sh"

#### How to use this script
# Since there is no user input required, all customizations to commands
# are set as veriables at the beginnig of the script. All customizations
# to files that would be configured with a text editor of choice would
# be done on template files found in this project root directory.

### Customizations
GITDIR=$(pwd)
DISK=/dev/nvme0n1

#### BTRFS Subvolumes
# Should not contain the root and its child subvolumes. The "root"
# subvolume is for the root user, not the system root directory. There
# are two arrays, "SUBVOLNAMES" and "SUBVOLDIRS", that contain the name
# of the subvolume and the directory under "/mnt/gnetoo/" that sed
# subvolume should be mounted to respectively. The index of each arry
# should match the name and the desired location.
ROOTSUBVOL=gentoo
SUBVOLNAMES=(home root snapshots virtual)
SUBVOLDIRS=(home root snapshots virtual)
SUBVOLOPTIONS=ssd,noatime,compress=lzo

### Mount partitions
echo "Mounting partitions ..."
mount -t btrfs -o $SUBVOLOPTIONS,subvol=$ROOTSUBVOL "${DISK}p2" /mnt/gentoo
mkdir /mnt/gentoo/{boot,boot/efi}
for ((i=0; i<${SUBVOLUMENAMES[@]}; i++)); do
    mkdir /mnt/gentoo/$i
done
mount /dev/"${DISK}p1" /mnt/gentoo/boot/efi
mount -t btrfs -o $SUBVOLOPTIONS "${DISK}p2" /mnt/gentoo/mnt/btrfs
if [ "${#SUBVOLUMENAMES[@]}" -eq "${#SUBVOLUMEDIRS[@]}" ]; then
    for ((i=0; i<${SUBVOLUMENAMES[@]}; i++)); do
        mount -t btrfs -o $SUBVOLUMEOPTIONS,subvol=${SUBVOLNAMES[$i]} "${DISK}p2" /mnt/gentoo/${SUBVOLDIRS[$i]}
    done
fi

### Install the Stage 3 tarball
echo "Installing State 3 tarball ..."
[ ! -d "/mnt/gentoo/root/" ] && mkdir /mnt/gentoo/root
time wget -P /mnt/gentoo/root https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/20200811T132729Z/stage3-amd64-systemd-20200811T132729Z.tar.xz
echo "Extracting tarball ..."
time tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

### Configure portage
echo "Copying partage files ...."
rm -rf /etc/portage/package.use/
cp $GITDIR/package.use /mnt/gentoo/portage/
mv /mnt/gentoo/etc/portage/make.conf $GITDIR/backup
cp /etc/portage/make.conf /mnt/gentoo/etc/portage/make.conf.def
cp $GITDR/make.conf /mnt/gentoo/etc/portage/

### Chroot
echo "Changing root ..."
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount -t proc none proc
mount --rbind /sys sys
mount --make-rslave sys
mount --rbind /dev dev
mount --make-rslave dev
chroot /mnt/gentoo /bin/bash -c "su - -c /root/gentoo-installer/gentoo-install.sh"
. /etc/profile

### Update portage
echo "Updating portage ..."
time emerge-webrsync
eselect profile list
eselect profile set #profile
time emerge --update --deep --newuse @world

### Config
echo "Configuring timezones and locales ..."
echo "Europe/London" > /etc/timezone
emerge --config sys-libs/timezone-data
vi /etc/locale.gen
locale-gen
esselect locale list
eselect locale set # locale
env-update && source /etc/profile

### Fstab
echo "Installing genfstab ..."
time emerge app-portage/layman dev-vcs/git
layman -L
layman -a zscheile
emerge --nodeps arch-install-scripts asciidoc
cp /etc/fstab /etc/fstab.def
echo "Generating fstab ..."
genfstab -U -p / >> /ets/fstab

### Kernel
echo "Emerging kernel sources"
time emerge gentoo-sources:5.48 genkernel linux-firmware dracut btrfs-progs cryptsetup systemd
echo "Compiling kernel ..."
time genkernel --luks --btrfs --oldconfig --save-config --menuconfig --install all
echo "Generating inital ramdisk ..."

### System tools
echo "Emerging system tools ..."
time emerge sysklogd cronie mlocate btrfs-progs dosfstools dhcpcd
echo "Enabling system services ..."
systemctl enable cronie
systemctl enable dhcpcd
systemctl enable sshd
systemctl enable sysklogd
echo "Set root user password ..."
passwd

### Bootloader
echo "Installing bootloader ..."
bootctl --path /boot install
cp $GITDIR/gentoo.conf /boot/loader/entries/

### Exit
echo "Exiting chroot environment ..."
exit
echo "Unmounting disks ..."
cd /
umount -a
umount -R -l /mnt/gentoo/
lsblk
df
