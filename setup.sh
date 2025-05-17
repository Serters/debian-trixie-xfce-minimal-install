#!/bin/bash

# ================================================================
# --------------------->  START OF SCRIPT <-----------------------
# ================================================================

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
mkdir -p startup
mkdir -p backup

LOG_FILE="${SCRIPT_DIR}/setup.log"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "start: $(date)"

PROGRESS_FILE="${SCRIPT_DIR}/progress.txt"
touch "$PROGRESS_FILE"

# ================================================================
# --------------------->  START: Minimal Setup  <-----------------
# ================================================================

# ===============================
#        Sources & Upgrade
# ===============================

upgrade_packages() {
    echo "upgrade_packages START" > "$PROGRESS_FILE"

    sudo tee /etc/apt/sources.list >/dev/null <<'EOF'
deb https://deb.debian.org/debian trixie main contrib non-free non-free-firmware
# deb-src https://deb.debian.org/debian trixie main contrib non-free non-free-firmware

deb https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
# deb-src https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware

deb https://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
# deb-src https://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
EOF

    sudo apt update
    sudo apt upgrade
    sudo apt autopurge
    sudo apt autoclean

    echo "upgrade_packages END" > "$PROGRESS_FILE"
}
# To run upgrade_packages, uncomment the following line:
# upgrade_packages

# ===============================
#        Xfce4 Packages
# ===============================
install_minimal_xfce() {
    echo "install_minimal_xfce START" > "$PROGRESS_FILE"

    sudo apt install libxfce4ui-utils thunar xfce4-panel
    sudo apt install --no-install-recommends xfce4-session xfwm4 xfce4-terminal

    echo "install_minimal_xfce END" > "$PROGRESS_FILE"
}
# To run install_minimal_xfce, uncomment the following line:
# install_minimal_xfce

# ===============================
#        X Packages & Setup
# ===============================
install_xorg() {
    echo "install_xorg START" > "$PROGRESS_FILE"

    sudo apt install xserver-xorg
    sudo apt install --no-install-recommends xinit

    cat <<'EOF' >>~/.profile
# runs startx when logged into the TTY1.
# this starts the desktop enviorment on login.
if [[ -z "$DISPLAY" ]] && [[ $(tty) = /dev/tty1 ]]; then
  startx
fi
EOF

echo "install_xorg END" > "$PROGRESS_FILE"
}
# To run install_xorg, uncomment the following line:
# install_xorg

# ===============================
#        Package Cleanup
# ===============================

# Customize by deleting lines in clean_packages as needed:
clean_packages() {
    echo "clean_packages START" > "$PROGRESS_FILE"

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

    echo "clean_packages END" > "$PROGRESS_FILE"
}
# To remove unnecessary packages, uncomment the following line:
# clean_packages

# ================================================================
# --------------------->  END: Minimal Setup  <-------------------
# ================================================================

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
    sudo apt install ufw && sudo ufw enable
    sudo apt install gparted synaptic

    # resource monitors
    sudo apt install htop btop fastfetch

    # fonts
    sudo apt install --no-install-recommends fonts-noto-core fonts-noto-color-emoji

    # kitty terminal
    # sudo apt install --no-install-recommends kitty

    # media-player, image-viewer & text editor
    sudo apt install --no-install-recommends mpv ristretto geany

    # whisker menu, screenshot, clipboard history, wallpaper tool & video thumbanils
    sudo apt install --no-install-recommends xfce4-screenshooter xfce4-clipman xfce4-whiskermenu-plugin xwallpaper ffmpegthumbnailer

    # cli tools
    sudo apt install curl git make cryptsetup

    # brave browser
    sudo curl -fsS https://dl.brave.com/install.sh | sh

    # firefox browser
    # sudo apt install firefox-esr

    echo "install_extra_tools END" > "$PROGRESS_FILE"
}
# To run install_extra_tools, uncomment the following line:
# install_extra_tools

# ===============================
#        System Utilities
# ===============================

install_connman() {
    echo "install_connman START" > "$PROGRESS_FILE"

    sudo apt install --no-install-recommends connman-gtk
    sudo apt install wpasupplicant
    # sudo apt install bluez

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

install_cbatticon() {
    echo "install_cbatticon START" > "$PROGRESS_FILE"

    sudo apt install cbatticon

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

install_volumeicon() {
    echo "install_volumeicon START" > "$PROGRESS_FILE"

    sudo apt install volumeicon-alsa

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

# To install system trey tools, uncomment the lines you need:
# install_connman
# install_cbatticon
# install_volumeicon

# ================================================================
# --------------------->  END: Utils Setup  <---------------------
# ================================================================

# ================================================================
# --------------------->  START: Tweaks Setup  <------------------
# ================================================================

# ===============================
#        /tmp partition
# ===============================
# To change the size of /tmp partition to 2GiB, uncomment the following line:
#sudo sed -i 's/size=50%%/size=2G/' /usr/lib/systemd/system/tmp.mount

move_brave_cache() {
    cd ~/.cache
    rm -rf BraveSoftware
    ln -s /tmp BraveSoftware
}
# To move brave cache to ram, uncomment the following line:
# move_brave_cache

move_thumbnails_cache() {
    cd ~/.cache
    rm -rf thumbnails
    ln -s /tmp thumbnails
}
# To move thumbnails cache to ram, uncomment the following line:
# move_thumbnails_cache

# ===============================
#        Disable Modules
# ===============================

blacklist_modules() {
    # Blacklist Bluetooth
    echo "blacklist btusb" | sudo tee /etc/modprobe.d/blacklist-bluetooth.conf

    # Blacklist Webcam
    echo "blacklist uvcvideo" | sudo tee /etc/modprobe.d/blacklist-webcam.conf

    cat >>~/.bash_aliases <<EOF
alias bluetooth-start="sudo modprobe -v btusb"
alias webcam-start="sudo modprobe -v uvcvideo"
alias bluetooth-stop="sudo modprobe -r btusb"
alias webcam-stop="sudo modprobe -r uvcvideo"
EOF
}
# To disable bluetooth and webcam modules, uncomment the following line:
# blacklist_modules

# ===============================
#        Disable Services
# ===============================
#sudo systemctl disable bluetooth

sudo systemctl mask ofono
sudo systemctl mask dundee

#sudo systemctl disable apt-daily-upgrade.timer
#sudo systemctl disable apt-daily.timer

# ===============================
#        Startup scripts
# ===============================
mute_on_startup() {
    mkdir -p ~/.config/autostart

    cat <<'EOF' >"$SCRIPT_DIR/startup/mute_volume.sh"
# Mute the Master channel
amixer sset Master mute

# Set the Master channel volume to 0%
amixer sset Master 0%
EOF
    chmod +x "$SCRIPT_DIR/startup/mute_volume.sh"

    cat >~/.config/autostart/volume.desktop <<EOF
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=volume on boot
Comment=
Exec=${SCRIPT_DIR}/startup/mute_volume.sh
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false
EOF   
}
# To mute volume on startup, uncomment the following line:
# mute_on_startup

set_xwallpaper() {
    mkdir -p "$HOME/.config/autostart"
    echo "xwallpaper --center \"$SCRIPT_DIR/assets/wallpaper.png\"" >"$SCRIPT_DIR/startup/wallpaper.sh"
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
}
# To set a wallpaper using xwallpaper, uncomment the following line:
# set_xwallpaper

# ===============================
#        Xfce Tweaks
# ===============================
pkill xfconfd

enable_numpad() {
    mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml/

    cp -fv /assets/keyboards.xml ~/.config/xfce4/xfconf/xfce-perchannel-xml/
}
# To enable numpad on boot, uncomment the following line:
# enable_numpad

configure_shortcuts() {
    mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml/

    cp -fv /assets/xfce4-keyboard-shortcuts.xml ~/.config/xfce4/xfconf/xfce-perchannel-xml/
}
# To enable whisker menu on super key, uncomment the following line:
# configure_shortcuts

configure_xfwm() {
    mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml/

    cp -fv /assets/xfwm4.xml ~/.config/xfce4/xfconf/xfce-perchannel-xml/
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

