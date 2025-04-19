# ===============================
#        Start of Script
# ===============================
echo "setup-min.sh start ..."

# ===============================
#        Apt Sources
# ===============================
sudo tee /etc/apt/sources.list > /dev/null << 'EOF'

deb https://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian trixie main contrib non-free non-free-firmware

deb https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb-src https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware

deb https://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
EOF

sudo apt update && sudo apt upgrade -y
# ===============================
#        Xfce4 Packages
# ===============================
sudo apt install libxfce4ui-utils -y
sudo apt install thunar -y
sudo apt install xfce4-panel -y
sudo apt install --no-install-recommends xfce4-session -y
sudo apt install --no-install-recommends xfdesktop4 -y
sudo apt install --no-install-recommends xfwm4 -y
sudo apt install xfce4-whiskermenu-plugin -y
sudo apt install --no-install-recommends xfce4-terminal -y

# ===============================
#        X Packages & Setup
# ===============================
sudo apt install xserver-xorg
sudo apt install --no-install-recommends xinit -y
echo '
# startx if logged in to tty1

if [[ -z "$DISPLAY" ]] && [[ $(tty) = /dev/tty1 ]]; then
  startx
fi' >> ~/.profile

# ===============================
#        Package Cleanup
# ===============================
sudo apt autopurge
sudo apt autoremove
sudo apt autoclean

# ===============================
#        End of Script
# ===============================
echo "setup-min.sh completed successfully!"
