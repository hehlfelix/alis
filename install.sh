#!/bin/sh
 # Installationsskript für Arch Linux x64
 # Ziel: T440s mit 250GB Crucial SSD

read -s -p "Enter disc encryption password: " passwd
printf "\n"
read -s -p "Confirm disc encryption password: " confirm_passwd
volGroup="MainVG"
luksDevice="cryptlvm"
root_part_size="40G"
if [ "$passwd" != "$confirm_passwd" ];then
    exit 255
fi

# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "default" will send a empty
# line terminated with a newline to take the fdisk default.
# regex explained:
# \s* <- any amount of whitespace at the beginning of the line
# \([\+0-9a-zA-Z]*\)  <- capture group 1, which captures all fdisk commands
# .*  <- any character after the capture group
# \1 <- replace everything with capture group 1
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sda
    o # clear the in memory partition table
    n # new partition
    p # primary partition
    1 # partition number 1
      # default - start at beginning of disk
    +200M # 100 MB boot partition
    n # new partition
    p # primary partition
    2 # partition number 2
      # default, start immediately after preceding partition
      # default, extend partition to end of disk
    a # make a partition bootable
    1 # bootable partition is partition 1 -- /dev/sda1
    t # change type of partition
    2 # partition to change the type
    8e # Hexcode for LVM partition type
    p # print the in-memory partition table
    w # write the partition table
    q # and we're done
EOF

printf "starting disc encryption..\n"
# create LUKS encrypted container on system partition
printf "$passwd" | cryptsetup --batch-mode luksFormat --type luks2 /dev/sda2 -
printf "disc encryption finished\n"
printf "open encrypted drive\n"
printf "$passwd" | cryptsetup open /dev/sda2 $luksDevice -
printf "creating physical volume\n"
pvcreate /dev/mapper/$luksDevice
printf "creating volume group\n"
vgcreate $volGroup /dev/mapper/$luksDevice
printf "create logical volume for root filesystem\n"
lvcreate -L $root_part_size $volGroup -n root &> /dev/null
printf "create logical volume for swap\n"
lvcreate -L 1G $volGroup -n swap &> /dev/null
printf "create logical volume for /home\n"
lvcreate -l 100%FREE $volGroup -n home &> /dev/null

printf "creating filesystem on each logical volume..."
mkfs.ext4 /dev/$volGroup/root -L root &> /dev/null
mkfs.ext4 /dev/$volGroup/home -L home &> /dev/null
mkswap /dev/$volGroup/swap -L swap &> /dev/null

printf "mounting volumes...\n"
mount /dev/$volGroup/root /mnt/
mkdir /mnt/home
mount /dev/$volGroup/home /mnt/home
swapon /dev/$volGroup/swap

printf "preparing boot partition...\n"
mkfs.ext4 /dev/sda1 &> /dev/null
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

printf "edit mirrorlist...\n"
sed -i 's/^/#/g' /etc/pacman.d/mirrorlist
sed -i 's/^#\(.*halifax.*\)/\1/' /etc/pacman.d/mirrorlist

printf "Installing base packages...\n"
pacstrap /mnt/ base

cp ./chroot.sh /mnt/

printf "Generating fstab...\n"
genfstab -U /mnt/ >> /mnt/etc/fstab

printf "chroot into the new system...\n"
arch-chroot /mnt/ ./chroot.sh
