links: [[Linux]]
tags: #linux #fedora #grub #dual-boot #windows

---
# USB Hardware Boot Key for Dual-Boot (GRUB Probe Method)

Automatically boot straight into Windows 11 when a specific USB flash drive is inserted at startup. When the USB is missing, it skips straight into Fedora with a minimal timeout delay.

## How it Works

Instead of making the USB drive bootable, the internal GRUB bootloader probes all connected storage devices for a specific dummy tag file (`boot_windows.tag`) early in the boot sequence. If found, it routes directly to the persistent Windows UEFI boot ID.

## Step-by-Step Configuration

### 1. Extract the Windows Persistent Entry ID

Find the stable, immutable `osprober` menuentry ID generated for your Windows partition:

```bash
sudo grep -i "menuentry 'Windows" /boot/grub2/grub.cfg

```

*Example Output:* Look for the ID string right after `$menuentry_id_option`:
`menuentry 'Windows Boot Manager...' ... $menuentry_id_option 'osprober-efi-BF8A-1591'`

### 2. Create the Custom GRUB Hook

Create or edit your executable script ahead of the standard menu entries:

```bash
sudo nano /etc/grub.d/01_usb_timeout

```

Paste the following script structure. This version forces GRUB to load filesystem drivers to ensure early USB hardware detection and targets the unique hardware ID:

```bash
#!/bin/sh
cat << 'EOF'
# Load essential disk layout and filesystem drivers for USB detection
insmod part_gpt
insmod part_msdos
insmod fat
insmod ntfs
insmod ext2

# Scan all connected devices for the trigger file
search --no-floppy --file --set=usb_present /boot_windows.tag

if [ -n "$usb_present" ]; then
    # Update-proof: Targets the persistent UEFI UUID instead of volatile /dev/ paths
    set default="osprober-efi-BF8A-1591"
    set timeout=0
else
    # Default to Fedora (Index 0) with a fast timeout
    set default=0
    set timeout=1
fi
EOF

```

### 3. Sanitize, Permissions & Compile

To prevent system updates or text-editor mismatches from injecting hidden Windows carriage returns (`\r\n`), sanitize the script line endings, make it executable, and compile it directly to the master Fedora configuration path:

```bash
# Strip hidden carriage returns
sudo sed -i 's/\r$//' /etc/grub.d/01_usb_timeout

# Grant execution rights
sudo chmod +x /etc/grub.d/01_usb_timeout

# Rebuild the master GRUB configuration file
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

```

### 4. Prepare the USB Key

Create an empty file named exactly `boot_windows.tag` in the root directory of your flash drive:

```bash
touch /run/media/ouzx/YOUR_USB_NAME/boot_windows.tag

```

*(Make sure the USB filesystem is healthy and formatted as FAT32, NTFS, or Ext2/3/4 so GRUB can read it natively).*

---

## 🔍 Verification & Troubleshooting

### Confirm Script Injection

Before rebooting, verify that your script successfully baked into the master file:

```bash
sudo grep -A 15 "01_usb_timeout" /boot/grub2/grub.cfg

```

If you see your `search` and `if` conditional logic outputted between the file tags, the compile was completely successful.

### Test Live USB Visibility

To test if GRUB can physically see your USB key from the desktop without rebooting, run:

```bash
sudo grub2-fstest /boot/grub2/grub.cfg search --file /boot_windows.tag

```

If it outputs a drive mapping (e.g., `hd1,gpt1`), GRUB's storage probe is working perfectly.

---

## 🚨 Emergency Safety Nets

If something goes wrong with a future script modification, use these hardware overrides to bypass the automated loop:

1. **Motherboard Boot Menu (F9):** Turn on the laptop and immediately spam **F9** to access the HP OMEN boot menu. This bypasses GRUB entirely and lets you select your internal Fedora or Windows UEFI target directly from the firmware.
2. **GRUB Intercept (ESC):** Spam **Escape** immediately after the POST screen. This tells GRUB to halt any automated countdown timers or instant-boots, forcing the traditional visual menu to stay on screen.