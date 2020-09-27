#!/bin/sh
### About
# Create a partition table for an unencrypted BTRFS file sytem plus an
# EFI system partition.

### How to use this script

### Partition customization
DISK=/dev/nvme0n1
ESPSIZE=550MiB
SUBVOLS=(gentoo gentoo/tmp gentoo/var home root snapshots virtual)
SUBVOLOPTIONS=ssd,noatime,compress=lzo

### Main
echo "Partitoning disks ..."
sgdisk --zap-all $DISK

sgdisk --clear \
       --new=1:0:$ESPSIZE \
       --new=2:0:0 \
       $DISK

echo "Formatting partitions ..."
mkfs.vfat "${DISK}p1"
mkfs.btrfs -f "${DISK}p2"

echo "$Creating BTRFS subvolumes"
mount -t btrfs -o $SUBVOLOPTIONS "${DISK}p2" /mnt/
cd /mnt/btrfs
for i in $SUBVOLOPTIONS; do
    btrfs subvolume create $i
done
