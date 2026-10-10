# Xiaomi Pad 5 (`nabu`) - Arch Linux ARM Packages

Arch Linux ARM package repository and mainline kernel recipes for the **Xiaomi Pad 5** (`nabu`, Qualcomm SM8150).

## Repository Contents

- **`packages/linux-nabu`**: Mainline Linux 6.16.0 kernel package tracking the postmarketOS `sm8150` tree.
- **`packages/linux-firmware-xiaomi-nabu`**: Proprietary DSP and peripheral firmware blobs, including the calibrated WCN3990 Wi-Fi Board Data File (BDF) to resolve the ~15 Mbps throughput cap.
- **`packages/alsa-ucm-conf-xiaomi-nabu`**: ALSA Use Case Manager (UCM2) configuration profiles for Cirrus CS35L41 quad-speakers and WCD9341 microphones.
- **`scripts`**: Repository creation (`create-repo.sh`) and maintenance utilities.

## Building the Kernel & Packages

On an Arch Linux x86_64 host with cross-compilation tools installed (`aarch64-linux-gnu-gcc`, `aarch64-linux-gnu-binutils`):

```bash
# Build kernel
cd packages/linux-nabu
CARCH=aarch64 makepkg --holdver -d --skipinteg

# Build firmware
cd ../linux-firmware-xiaomi-nabu
makepkg -d --skipinteg

# Build audio UCM profiles
cd ../alsa-ucm-conf-xiaomi-nabu
makepkg -d --skipinteg
```

## Creating the Custom Pacman Repository

Generate `repo/nabu.db.tar.zst` containing all packages:

```bash
./scripts/create-repo.sh
```

## Installing on Nabu

### 1. Wi-Fi Firmware Guard Policy (Prevent Speed Regressions)
To prevent upstream `linux-firmware-atheros` updates from overwriting the calibrated Qualcomm WCN3990 `board-2.bin` and `wlanmdsp.mbn`:

Edit `/etc/pacman.conf` on the tablet and add:
```ini
NoExtract = usr/lib/firmware/ath10k/WCN3990/hw1.0/*
```

### 2. Transfer Packages to Tablet
```bash
scp packages/*/*.pkg.tar.zst nabu@<tablet-ip>:/home/nabu/
```

### 3. Backup Working EFI Image (Fallback Guarantee)
```bash
sudo cp /boot/efi/EFI/arch/arch-linux-nabu.efi /boot/efi/EFI/arch/arch-linux-nabu-fallback.efi
```

### 4. Install Packages
```bash
sudo pacman -U /home/nabu/*.pkg.tar.zst
```

### 5. Verify Unified Kernel Image (UKI) Generation
```bash
ls -lh /boot/efi/EFI/arch/arch-linux-nabu.efi
```

### 6. Reboot & Verify
```bash
uname -r
# Check Wi-Fi throughput and driver state:
dmesg | grep ath10k
```

## Credits & Upstream Lineage

- [Kumar-Jy / linux-nabu](https://github.com/Kumar-Jy/linux-nabu) - Xiaomi Pad 5 mainline kernel integration & display bringup
- [postmarketOS Qualcomm SM8150 Tree](https://gitlab.postmarketos.org/soc/qualcomm-sm8150/linux) - Mainline Linux SM8150 SoC port
- [Pocketblue Fedora Mobility](https://github.com/pocketblue/pocketblue)
- [nabu-firmware](https://gitlab.postmarketos.org/panpanpanpan/nabu-firmware)

