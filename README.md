# Xiaomi Pad 5 (`nabu`) - Arch Linux ARM Packages

Arch Linux ARM package repository and mainline kernel recipes for the **Xiaomi Pad 5** (`nabu`, Qualcomm SM8150).

## Repository Contents

- **`packages/linux-nabu`**: Mainline Linux kernel package for `nabu` tracking the postmarketOS `sm8150` tree.
- **`packages/linux-firmware-xiaomi-nabu`**: Proprietary DSP and peripheral firmware recipes for Xiaomi Pad 5 hardware.
- **`packages/alsa-ucm-conf-xiaomi-nabu`**: ALSA Use Case Manager configuration profiles for mobile audio.
- **`scripts`**: Helper automation and packaging utilities.

## Building the Kernel

On an Arch Linux x86_64 host with cross-compilation tools installed (`aarch64-linux-gnu-gcc`, `aarch64-linux-gnu-binutils`):

```bash
cd packages/linux-nabu
CARCH=aarch64 makepkg -sc --skipinteg
```

## Installing on Nabu

1. Transfer package to tablet:
   ```bash
   scp packages/linux-nabu/linux-nabu-*.pkg.tar.zst nabu@<tablet-ip>:/home/nabu/
   ```
2. Backup existing EFI image (safe fallback guarantee):
   ```bash
   sudo cp /boot/efi/EFI/arch/arch-linux-nabu.efi /boot/efi/EFI/arch/arch-linux-nabu-fallback.efi
   ```
3. Install package:
   ```bash
   sudo pacman -U /home/nabu/linux-nabu-*.pkg.tar.zst
   ```
4. Verify Unified Kernel Image (UKI) generation:
   ```bash
   ls -lh /boot/efi/EFI/arch/arch-linux-nabu.efi
   ```
5. Reboot to test.

## Credits & Upstream Lineage

- [postmarketOS Qualcomm SM8150 Tree](https://gitlab.postmarketos.org/soc/qualcomm-sm8150/linux)
- [Pocketblue Fedora Mobility](https://github.com/pocketblue/pocketblue)
- [nabu-firmware](https://gitlab.postmarketos.org/panpanpanpan/nabu-firmware)
