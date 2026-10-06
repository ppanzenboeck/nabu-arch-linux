# Project Nabu Renaissance: Arch Linux ARM Maintenance Blueprint

## 1. Executive Summary & Context

This blueprint is designed for the **Antigravity agent / developer on the x86_64 Arch Linux build workstation (Intel i9-10900KF)** to set up a reproducible packaging, cross-compilation, and release pipeline for the **Xiaomi Pad 5 (`nabu`)** on **Arch Linux ARM (aarch64)**.

### Target Hardware & State:
- **Device:** Xiaomi Pad 5 (`nabu`)
- **SoC:** Qualcomm Snapdragon 860 / SM8150-AC (`sm8150`)
- **Current Kernel:** `6.14.0-1-nabu-gdefb39db31e6-dirty` (from abandoned repo `build@tx0.su` / `timoxa0`)
- **Bootloader:** EDK2 / UEFI (systemd-boot) with Unified Kernel Image (UKI) at `/boot/efi/EFI/arch/arch-linux-nabu.efi`
- **Root Filesystem:** Arch Linux ARM (rolling, fully up to date)
- **Known Reference Config:** The running, working kernel configuration has been extracted from `/proc/config.gz` and saved on the tablet at `/home/nabu/config-6.14-running`.

---

## 2. Upstream Kernel & Firmware Lineage

Do **not** attempt to maintain patches against vanilla Linus `master` manually. Active hardware support for `sm8150` and `nabu` (display DPU, Novatek touchscreen, audio UCM, ath10k Wi-Fi, battery/LN8000 charging) is maintained by two upstream projects:

1. **postmarketOS SM8150 Tree (Recommended Kernel Source)**:
   - Git: `https://gitlab.postmarketos.org/soc/qualcomm-sm8150/linux.git`
   - Canonical home for SM8150 SoC maintenance.
2. **Pocketblue (Fedora Mobility for Nabu)**:
   - Git: `https://github.com/pocketblue/pocketblue`
   - Excellent reference for mobile device services (e.g. `ath10k-shutdown.service`), Wayland scaling, and mobile audio profiles.
3. **Firmware Source**:
   - `https://gitlab.postmarketos.org/panpanpanpan/nabu-firmware`
   - Packages Qualcomm DSP blobs: `adsp.mbn`, `cdsp.mbn`, `modem.mbn`, `wlanmdsp.mbn`, `slpi_nb.mbn`, `venus.mbn`, `a640_zap.mbn`.

---

## 3. GitHub Repository Setup (To Do on Workstation)

Using `gh` (GitHub CLI) on the Arch Linux x86_64 build host:

```bash
# 1. Create the repository
gh repo create nabu-arch-linux --public --description "Arch Linux ARM package repository and mainline kernel for Xiaomi Pad 5 (nabu)" --clone
cd nabu-arch-linux

# 2. Directory Structure
mkdir -p packages/linux-nabu \
         packages/linux-firmware-xiaomi-nabu \
         packages/alsa-ucm-conf-xiaomi-nabu \
         scripts
```

---

## 4. Build Environment Configuration (Arch Linux x86_64)

### Required Packages:
```bash
sudo pacman -S --needed \
    base-devel \
    git \
    aarch64-linux-gnu-gcc \
    aarch64-linux-gnu-binutils \
    bc \
    dtc \
    kmod \
    uboot-tools \
    systemd-ukify \
    arch-install-scripts
```

---

## 5. Kernel Package Blueprint (`packages/linux-nabu/PKGBUILD`)

Create `packages/linux-nabu/PKGBUILD`:

```bash
# Maintainer: Your Name <your.email@domain.com>
pkgname=linux-nabu
pkgver=6.16.0 # Adjust to target postmarketOS sm8150 branch/tag
pkgrel=1
pkgdesc="Linux mainline kernel for Xiaomi Pad 5 (SM8150)"
arch=('aarch64')
url="https://gitlab.postmarketos.org/soc/qualcomm-sm8150/linux"
license=('GPL-2.0-only')
depends=(
  'coreutils'
  'initramfs'
  'kmod'
  'linux-firmware-xiaomi-nabu'
)
optdepends=(
  'wireless-regdb: regulatory domain database'
)
provides=('WIREGUARD-MODULE')
source=(
  "git+https://gitlab.postmarketos.org/soc/qualcomm-sm8150/linux.git#branch=sm8150-mainline"
  "config"
  "linux-nabu.preset"
)
sha256sums=(
  'SKIP'
  'SKIP'
  'SKIP'
)

prepare() {
  cd linux
  cp "${srcdir}/config" .config
  make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig
}

build() {
  cd linux
  make -j$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image dtbs modules
}

package() {
  cd linux

  # Install modules
  make ARCH=arm64 INSTALL_MOD_PATH="${pkgdir}/usr" INSTALL_MOD_STRIP=1 modules_install

  # Remove build and source symlinks pointing to build host paths
  rm -f "${pkgdir}/usr/lib/modules/${pkgver}-nabu/build"
  rm -f "${pkgdir}/usr/lib/modules/${pkgver}-nabu/source"

  # Install kernel image and Device Tree Blob (DTB)
  install -Dm644 arch/arm64/boot/Image "${pkgdir}/boot/vmlinuz-linux-nabu"
  install -Dm644 arch/arm64/boot/dts/qcom/sm8150-xiaomi-nabu.dtb "${pkgdir}/boot/dtb-linux-nabu"

  # Install mkinitcpio preset
  install -Dm644 "${srcdir}/linux-nabu.preset" "${pkgdir}/etc/mkinitcpio.d/linux-nabu.preset"
}
```

### Mkinitcpio Preset (`packages/linux-nabu/linux-nabu.preset`):
```ini
ALL_kver="/boot/vmlinuz-linux-nabu"

PRESETS=('default')

default_uki="/boot/efi/EFI/arch/arch-linux-nabu.efi"
default_options="--dtb /boot/dtb-linux-nabu"
```

---

## 6. Wi-Fi Firmware Guard Policy

To prevent upstream `linux-firmware-atheros` updates from overwriting the Qualcomm WCN3990 `wlanmdsp.mbn` file on the tablet:
1. In `packages/linux-firmware-xiaomi-nabu/PKGBUILD`, install `wlanmdsp.mbn` into `/usr/lib/firmware/ath10k/WCN3990/hw1.0/wlanmdsp.mbn`.
2. Add a pacman hook or instruct users to add to `/etc/pacman.conf`:
   ```ini
   NoExtract = usr/lib/firmware/ath10k/WCN3990/hw1.0/wlanmdsp.mbn
   ```

---

## 7. Build Execution & Safe Deployment Flow

### Building on the i9-10900KF:
Run the cross-compilation directly using makepkg with architecture override:
```bash
cd packages/linux-nabu
CARCH=aarch64 makepkg -sc --skipinteg
```
*(Compilation on all 20 threads of the 10900KF takes approximately 4–5 minutes).*

### Safe Testing on Nabu (No Nuking Guarantee):
1. **Never delete the existing working kernel first.**
   Ensure `/boot/vmlinuz-6.14.0-1-nabu-gdefb39db31e6-dirty` remains in `/boot/` as an EFI fallback entry.
2. Transfer package to tablet:
   ```bash
   scp packages/linux-nabu/linux-nabu-*.pkg.tar.zst nabu@192.168.1.54:/home/nabu/
   ```
3. Test install on Nabu:
   ```bash
   sudo pacman -U /home/nabu/linux-nabu-*.pkg.tar.zst
   ```
4. Check generated UKI:
   ```bash
   ls -lh /boot/efi/EFI/arch/arch-linux-nabu.efi
   ```
5. Reboot to test.

---

## 8. Long-Term Maintenance: Building a Custom Pacman Repo

Once the initial kernel boots reliably:
1. Host a repository index on your server or GitHub Releases (`repo-add nabu.db.tar.zst *.pkg.tar.zst`).
2. Add the custom repository section to `/etc/pacman.conf` on the tablet:
   ```ini
   [nabu]
   SigLevel = Optional TrustAll
   Server = https://github.com/<your-username>/nabu-arch-linux/releases/latest/download
   ```
3. Device updates will henceforth seamlessly flow through standard `pacman -Syu`.
