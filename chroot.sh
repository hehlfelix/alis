#!/bin/bash
read -s -p "Enter hostname: " HOSTNAME
read -s -p "Enter username: " USERNAME
read -s -p "Enter user password: " password
printf "setting up timezone...\n"
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

printf "setting locle...\n"
sed -i 's/^#\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
# Weil US Layout
# printf "KEYMAP=de-latin1" > /etc/vconsole.conf


printf "setting up network...\n"
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager.service
systemctl start NetworkManager.service
printf "$HOSTNAME" > /etc/hostname


printf "configure mkinitcpio..."
sed -i 's/^HOOKS.*/HOOKS=\(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck\)/' /etc/mkinitcpio.conf

mkinitcpio -p linux

# Todo: Konfiguration des Intel-ucode Firmware Patches!
# Installation Intel-ucode
pacman -S syslinux intel-ucode --noconfirm

syslinux-install_update -i -a -m
sed -i 's/APPEND.*/APPEND cryptdevice=\/dev\/sda2:cryptlvm root=\/dev\/mapper\/MainVG-root rw lang=de locale=de_DE.UTF-8/' /boot/syslinux/syslinux.cfg


printf "installing additional packages...\n"

# Todo: Struktur der Pakete nach Funktion / Anwendungsgebiet erstellen!

pacman -S --noconfirm  graphviz keepassxc htop rsync virtualbox virtualbox-host-modules-arch texlive-most texlive-bin biber pandoc powerline-fonts



# Anwendungen: 
pacman -S --noconfirm firefox filezilla transmission-cli mumble hexchat thunderbird

# Terminal Emulator relevante Pakete:
pacman -S --noconfirm rxvt-unicode zsh 

# X11 relevante Pakete:
pacman -S --noconfirm xorg-server xorg-init 

# Netzwerk relevante Pakete:
pacman -S --noconfirm wget curl git rsync aircrack-ng bmon mtr tcpdump nm-connection-editor openssh nmap wireshark-qt

# Dateiverwaltung relevante Pakete:
pacman -S --noconfirm nautilus unzip borg nfs-utils cifs-utils 

# i3 relevante Pakete:
pacman -S --noconfirm i3-wm i3lock i3status dmenu

# Softwaredevelopement relevante Pakte:
pacman -S --noconfirm base-devel eclipse-java atom vim git

# LaTeX relevante Pakete:
pacman -S --noconfirm texlive-most texlive-bin biber pandoc 

# Sonstige Pakete:
pacman -S --noconfirm screenfetch gnome-disk-utility nextcloud-client neofetch sudo redshift 

# Font relevante Pakete:
pacman -S --noconfirm powerline-fonts

# Science relevante Pakete:
pacman -S --noconfirm octave geogebra

#
#
#
# Todo: Sound Config, i3 Config kopieren / anpassen, XKeyBindings editieren, Terminal Emulator Config editieren / Gruppenzugehoerigkeiten anpassen /
#
#
#


printf "adding user...\n"
useradd --uid 1000 --user-group --create-home --groups wheel --home-dir /home/$USERNAME --shell /usr/bin/zsh $USERNAME
printf "$password\n$password\n" | passwd $USERNAME
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers.d/00_allow_wheel

