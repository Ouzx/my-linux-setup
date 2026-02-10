#!/usr/bin/env bash

set -e

ROOT_UID=0
THEME_NAME="Particle-sidebar"
THEME_SOURCE_DIR="Particle-sidebar"
THEME_DIR="/boot/grub2/themes"
MAX_DELAY=10

prompt() {
  case "$1" in
    -i) printf "[INFO] %b" "$2" ;;
    -s) printf "[OK] %b" "$2" ;;
    -e) printf "[ERROR] %b\n" "$2" ;;
    -w) printf "%b" "$2" ;;
    *)  printf "%b\n" "$1" ;;
  esac
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

prompt -w "Checking for root access...\n"

if [[ "$UID" -ne "$ROOT_UID" ]]; then
  prompt -e "Run me as root"
  exit 1
fi

prompt -i "Preparing theme directory...\n"
rm -rf "${THEME_DIR:?}/${THEME_NAME}"
mkdir -p "${THEME_DIR}/${THEME_NAME}"

prompt -i "Installing ${THEME_NAME} theme...\n"
cp -a "${THEME_SOURCE_DIR}/." "${THEME_DIR}/${THEME_NAME}"

prompt -i "Configuring GRUB...\n"

# Backup once
cp -an /etc/default/grub /etc/default/grub.bak

# Remove conflicting entries
sed -i \
  -e '/^GRUB_THEME=/d' \
  -e '/^GRUB_TERMINAL_OUTPUT=/d' \
  -e '/^GRUB_ENABLE_BLSCFG=/d' \
  /etc/default/grub

# Required for GRUB themes on Fedora
cat >> /etc/default/grub <<EOF
GRUB_TERMINAL_OUTPUT="gfxterm"
GRUB_ENABLE_BLSCFG="false"
GRUB_THEME="${THEME_DIR}/${THEME_NAME}/theme.txt"
EOF

prompt -i "Updating grub configuration...\n"

if has_command update-grub; then
  update-grub
elif has_command grub-mkconfig; then
  grub-mkconfig -o /boot/grub/grub.cfg
elif has_command zypper || has_command transactional-update; then
  grub2-mkconfig -o /boot/grub2/grub.cfg
elif has_command dnf || has_command rpm-ostree; then
  grub2-mkconfig -o /boot/grub2/grub.cfg
else
  prompt -e "No supported GRUB update command found"
  exit 1
fi

prompt -s "\nAll done! Reboot to see the sidebar theme.\n"
