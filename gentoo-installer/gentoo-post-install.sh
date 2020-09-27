#!/bin/sh
### Install emacs
# Add emacs use fag to "/etc/portage/make.conf"
emerge emacs
# TODO clone emacs config to "~/.emacsd.d/"

### Add a user
useradd -m -G wheel,audio,video admin
passwd admin
emacs /etc/sudoers # Fix sudo command
su admin

### Change portage to use git instead of rsync
# TODO add gentoo.conf file to the "gentoo-installer" directory
# cp $gitdr/gentoo.conf /etc/portage/repos.conf/gentoo.conf
# mv /var/db/repos/gentoo{,.bak}
# mkdir /var/db/repos/gentoo
# emerge --sync
# # Remove "/var/db/repos/gentoo.bak" manually

emerge ccache app-portage/cpuid2cpuflags sys-devel/distcc
mkdir -p /var/cache/ccache
chown root:portage /var/cache/ccache
chmod 2775 /var/cache/ccache

# /var/cache/ccache/ccachd.conf
max_size = 100.0G
umask = 002
compiler_check = %compiler% -v
cache_dir_levels = 3

# /etc/portage/make.conf
FEATURES="ccache"
CCACHE_DIR="/var/cache/ccache"

# add to /etc/profile:
export PATH="/usr/lib/ccache/bin${PATH:+:}$PATH"
export CCACHE_DIR="/var/cache/ccache"

# cpuid2cpuflags
cpuid2cpuflags
