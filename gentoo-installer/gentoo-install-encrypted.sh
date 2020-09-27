#!/bin/sh

# Set git repository directoy
gitdir=pwd

# Install the stage 3 tarball
cd /mnt/gentoo
time wget -P /mnt/gentoo/root https://bouncer.gentoo.org/fetch/root/all/releases/amd64/autobuilds/20200811T132729Z/stage3-amd64-systemd-20200811T132729Z.tar.xz
time tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

# Configure portage
rm -r /etc/portage/package.use
cp $gitdir/package.use /mnt/gentoo/portage
mv /mnt/gentoo/etc/portage/make.conf $gitdir/backup
cp /etc/portage/make.conf /mnt/gentoo/etc/portage/make.conf
cp /mnt/gentoo/etc/portage/make.conf /mnt/gentoo/etcp/portage/make.conf.def
echo "" > /mnt/gentoo/etc/portage/make.conf
echo "FEATURES="parallel-fetch parallel-install"" > /mnt/gentoo/etc/portage/make.conf
echo "MAKEOPTS=""" > /mnt/gentoo/etc/portage/make.conf
echo "USE="threads savedconfig systemd -gui -sound"" > /mnt/gentoo/etc/portage/make.conf
echo "VDEO_CARDS=""" > /mnt/gentoo/etc/portage/make.conf
vi /mnt/gentoo/etc/portage/make.conf

# Chroot
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

# Update portage
time emerge-webrsync
eselect profile list
eselect profile set #profile
time emerge --update --deep --newuse @world

# Config
echo "Europe/London" > /etc/timezone
emerge --config sys-libs/timezone-data
vi /etc/locale.gen
esselect locale list
eselect locale set # locale
env-update && source /etc/profile

# Fstab
time emerge app-portage/layman dev-vcs/git
layman -L
layman -a zscheile
emerge --nodeps arch-install-scripts
cp /etc/fstab /etc/fstab.def
genfstab -U -p / >> /ets/fstab

# Kernel
time emerge gentoo-sources:5.48 genkernel linux-firmware dracut btrfs-progs cryptsetup systemd
genkernel --luks --btrfs --oldconfig --save-config --menuconfig --install all
dracut -k /lib/modules/5.4.48-gentoo-x86_64/ --kver 5.4.48-gentoo -f

# System tools
time emerge sysklogd cronie mlocate btrfs-progs dosfstools dhcpcd
systemctl enable cronie
systemctl enable dhcpcd
systemctl enable sshd
systemctl enable sysklogd
passwd

# Bootloader
bootctl --path /boot install
cp $gitdir/gentoo.conf /boot/loader/entries/
echo "options	dobtrfs rd.luks=1 rd.luks.name=$rootpartition=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=gentoo" > /boot/loader/entries/gentoo.conf

# Exit
exit
cd /
umount -a
umount -R -l /mnt/gentoo/
lsblk
df
echo "Reboot?"
