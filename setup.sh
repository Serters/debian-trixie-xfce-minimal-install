#!/bin/bash

# ================================================================
# --------------------->  START OF SCRIPT <-----------------------
# ================================================================

# https://github.com/Serters/debian-trixie-xfce-minimal-install

# ===============================
#        Confirmation
# ===============================

# This script should be ran without sudo. The script will invoke sudo as needed.
if [ "$(id -u)" -eq 0 ]; then
    echo "Re-run the script without sudo."
    exit
fi

read -p "Type y to continue: " answer
if [[ "$answer" != "y" ]]; then
    echo "Aborted."
    exit 1
fi

sudo -v

SCRIPT_DIR=$(dirname "$(realpath "$0")")
mkdir -p assets
mkdir -p backup
mkdir -p logs
mkdir -p startup

LOG_FILE="${SCRIPT_DIR}/logs/setup.log"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "start: $(date)"

PROGRESS_FILE="${SCRIPT_DIR}/logs/progress.txt"
touch "$PROGRESS_FILE"

# ================================================================
# --------------------->  START: Minimal Setup  <-----------------
# ================================================================

# ===============================
#        Sources & Upgrade
# ===============================

upgrade_packages() {
	
	echo "upgrade_packages START" > "$PROGRESS_FILE"
	
    sudo apt update
    sudo apt upgrade -y
    sudo apt autopurge -y
    sudo apt autoclean -y

    echo "upgrade_packages END" > "$PROGRESS_FILE"
}
# To upgrade packages, uncomment the following line:
# upgrade_packages

# ===============================
#        Xfce4 Packages
# ===============================
install_minimal_xfce() {
    echo "install_minimal_xfce START" > "$PROGRESS_FILE"

    sudo apt install -y libxfce4ui-utils thunar xfce4-panel
    sudo apt install -y --no-install-recommends xfce4-session xfwm4 xfce4-terminal

    echo "install_minimal_xfce END" > "$PROGRESS_FILE"
}
# To install minimal xfce desktop environment, uncomment the following line:
# install_minimal_xfce

# ===============================
#        X Packages & Setup
# ===============================
install_xorg() {
    echo "install_xorg START" > "$PROGRESS_FILE"

    sudo apt install -y xserver-xorg
    sudo apt install -y --no-install-recommends xinit

    cat <<'EOF' >>~/.profile
# runs startx when logged into the TTY1.
# this starts the desktop enviorment on login.
if [[ -z "$DISPLAY" ]] && [[ $(tty) = /dev/tty1 ]]; then
  startx
fi
EOF

echo "install_xorg END" > "$PROGRESS_FILE"
}
# To install xorg, uncomment the following line:
# install_xorg

# ===============================
#        Minimal Standard Utils
# ===============================

# Customize by deleting lines in clean_packages as needed:
install_minimal_standard_system_utils() {
    sudo apt install -y bash-completion \
    bzip2 \
    dbus \
    file \
    liblockfile-bin \
    libnss-systemd \
    lsof \
    media-types \
    netcat-traditional \
    pciutils \
    ucf \
    usbutils \
    xz-utils
}
# To install minimal standard system utils, uncomment the following line:
# install_minimal_standard_system_utils

install_man() {
    sudo apt install -y man-db \
    manpages 
}
# To install manpages and man-db, uncomment the following line:
# install_man

# ===============================
#        Package Cleanup
# ===============================

# Customize by deleting lines in clean_packages as needed:
remove_packages() {
    echo "remove_packages START" > "$PROGRESS_FILE"

    sudo apt purge apt-listchanges \
        bind9-dnsutils \
        bind9-host \
        bind9-libs \
        dictionaries-common \
        doc-debian \
        emacsen-common \
        ethtool \
        iamerican \
        ibritish \
        ienglish-common \
        inetutils-telnet \
        ispell \
        task-english \
        util-linux-locales \
        wamerican \
        wtmpdb \
        zerofree \
        tasksel \
        tasksel-data \
        vim-tiny \
        vim-common \
        apparmor

    sudo apt autopurge
    sudo apt autoclean

    echo "remove_packages END" > "$PROGRESS_FILE"
}
# To remove unnecessary packages, uncomment the following line:
# remove_packages

# ================================================================
# --------------------->  END: Minimal Setup  <-------------------
# ================================================================

minimal_setup() {
	upgrade_packages
	install_minimal_xfce
	install_xorg
	install_minimal_standard_system_utils
	install_man
	remove_packages
}
# To run everything from the minimal setup, uncomment the following line:
# minimal_setup

# ================================================================
# --------------------->  START: Utils Setup  <-------------------
# ================================================================

# ===============================
#        Utility Packages
# ===============================

#  Customize by commenting or uncommenting lines in install_extra_tools as needed:
install_extra_tools() {
    echo "install_extra_tools START" > "$PROGRESS_FILE"

    # firewall, partition tools & graphical package manager
    sudo apt install -y ufw && sudo ufw enable
    sudo apt install -y gparted synaptic

    # resource monitors
    sudo apt install -y htop btop fastfetch

    # fonts
    sudo apt install -y --no-install-recommends fonts-noto-core fonts-noto-color-emoji

    # kitty terminal
    sudo apt install -y --no-install-recommends kitty

    # calculator, media-player, image-viewer, text editor & video thumbanils
    sudo apt install -y --no-install-recommends galculator mpv ristretto geany ffmpegthumbnailer

    # whisker menu, screenshot, clipboard history & wallpaper tool 
    sudo apt install -y --no-install-recommends xfce4-whiskermenu-plugin xfce4-screenshooter xfce4-clipman xwallpaper 

    # cli tools
    sudo apt install -y curl wget git make p7zip-full cryptsetup 

    # brave browser
    sudo curl -fsS https://dl.brave.com/install.sh | sh

    # firefox browser
    # sudo apt install -y firefox-esr

    # SSH
    # sudo apt install -y openssh-client openssh-server && sudo ufw allow ssh

    # other
    # sudo apt install -y vim tmux bc lm-sensors

    echo "install_extra_tools END" > "$PROGRESS_FILE"
}
# To run install_extra_tools, uncomment the following line:
# install_extra_tools

# ===============================
#        System Utilities
# ===============================

# network managment
install_connman() {
    echo "install_connman START" > "$PROGRESS_FILE"

    sudo apt install -y --no-install-recommends connman-gtk
    sudo apt install -y wpasupplicant
    sudo apt install -y bluez

    mkdir -p ~/.config/autostart
    cat >~/.config/autostart/connman-gtk.desktop <<EOF
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=network controls
Comment=
Exec=connman-gtk
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
EOF

    sudo systemctl disable wpa_supplicant
    sudo systemctl mask dundee
    sudo cp /etc/network/interfaces backup/interfaces.bak

    sudo tee /etc/network/interfaces >/dev/null <<EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback
EOF

    echo "install_connman END" > "$PROGRESS_FILE"
}

# power and battery information
install_cbatticon() {
    echo "install_cbatticon START" > "$PROGRESS_FILE"

    sudo apt install -y cbatticon light

    mkdir -p ~/.config/autostart
    cat >~/.config/autostart/cbatticon.desktop <<EOF
[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Application
Name=battery status
Comment=
Exec=cbatticon
OnlyShowIn=XFCE;
StartupNotify=false
Terminal=false
Hidden=false
EOF

    echo "install_cbatticon END" > "$PROGRESS_FILE"

}

# basic volume control
install_volumeicon() {
    echo "install_volumeicon START" > "$PROGRESS_FILE"

    sudo apt install -y volumeicon-alsa

    mkdir -p ~/.config/autostart
    cat >~/.config/autostart/volumeicon.desktop <<EOF
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=volume controls
Comment=
Exec=volumeicon
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
EOF

    echo "install_volumeicon END" > "$PROGRESS_FILE"
}

# To install lighter system trey tools, uncomment the lines you need:
# install_connman
# install_cbatticon
# install_volumeicon

# To install system trey tools (these have more features but use more resources), uncomment the lines you need:
# sudo apt install -y network-manager
# sudo apt install -y xfce4-power-manager
# sudo apt install -y xfce4-pulseaudio-plugin pulseaudio-module-bluetooth

# ================================================================
# --------------------->  END: Utils Setup  <---------------------
# ================================================================

# ================================================================
# --------------------->  START: Tweaks Setup  <------------------
# ================================================================

# ===============================
#        /tmp partition
# ===============================
# To change the size of /tmp partition to 2GiB (default value is 50% of your ram), uncomment the following line:
# sudo sed -i 's/size=50%%/size=2G/' /usr/lib/systemd/system/tmp.mount

move_brave_cache() {
	echo "move_brave_cache START" > "$PROGRESS_FILE"
	
    rm -rf "$HOME/.cache/BraveSoftware"
    ln -s /tmp "$HOME/.cache/BraveSoftware"
    
    echo "move_brave_cache END" > "$PROGRESS_FILE"
}
# To move brave cache to ram, uncomment the following line:
# move_brave_cache

move_thumbnails_cache() {
	echo "move_thumbnails_cache START" > "$PROGRESS_FILE"
	
    rm -rf "$HOME/.cache/thumbnails"
    ln -s /tmp "$HOME/.cache/thumbnails"
    
    echo "move_thumbnails_cache END" > "$PROGRESS_FILE"
}
# To move thumbnails cache to ram, uncomment the following line:
# move_thumbnails_cache

# ===============================
#        Disable Modules
# ===============================

disable_webcam() {
	echo "disable_webcam START" > "$PROGRESS_FILE"
	
    echo "blacklist uvcvideo" | sudo tee /etc/modprobe.d/blacklist-webcam.conf

    cat >>~/.bash_aliases <<EOF
alias webcam-start="sudo modprobe -v uvcvideo"
alias webcam-stop="sudo modprobe -r uvcvideo"
EOF

	echo "disable_webcam END" > "$PROGRESS_FILE"
}
# To disable the webcam module uncomment the following line:
# disable_webcam

# ===============================
#        Disable Services
# ===============================

disable_autoupdate() {
	sudo systemctl disable apt-daily-upgrade.timer
	sudo systemctl disable apt-daily.timer
}
# To disable automatic updates, uncomment the following line:
# disable_autoupdate

# ===============================
#        Startup scripts
# ===============================

set_xwallpaper() {
    mkdir -p "$HOME/.config/autostart"
    echo "xwallpaper --zoom \"$SCRIPT_DIR/assets/wallpaper.png\"" >"$SCRIPT_DIR/startup/wallpaper.sh"
    chmod +x "$SCRIPT_DIR/startup/wallpaper.sh"

    cat <<EOF >"$HOME/.config/autostart/wallpaper.desktop"
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=wallpaper
Comment=xwallpaper
Exec=${SCRIPT_DIR}/startup/wallpaper.sh
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
EOF

xwallpaper --zoom "$SCRIPT_DIR/assets/wallpaper.png"
}
# To set a wallpaper using xwallpaper, uncomment the following line:
# set_xwallpaper

# ===============================
#        Xfce Tweaks
# ===============================
pkill xfconfd

enable_numpad() {
    mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml/

    cp -fv "$SCRIPT_DIR/assets/keyboards.xml" "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/"
}
# To enable numpad on boot, uncomment the following line:
# enable_numpad

configure_shortcuts() {
    mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml/

    cp -fv "$SCRIPT_DIR/assets/xfce4-keyboard-shortcuts.xml" "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/"
}
# To enable whisker menu on super key, uncomment the following line:
# configure_shortcuts

configure_xfwm() {
    mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml/

    cp -fv "$SCRIPT_DIR/assets/xfwm4.xml" "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/"
}
# To configure xfwm, uncomment the following line:
# configure_xfwm

# ================================================================
# --------------------->  END: Tweaks Setup  <--------------------
# ================================================================

echo "end: $(date)"
# ================================================================
# --------------------->  END OF SCRIPT <-------------------------
# ================================================================

