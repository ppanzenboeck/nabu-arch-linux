# Addendum: Resolving the Xiaomi Pad 5 (nabu) Wi-Fi ~15 Mbps Speed Cap

## 1. Problem Statement
The Xiaomi Pad 5 (`nabu`) on Arch Linux ARM connects to Wi-Fi via the Qualcomm **WCN3990** chipset (`ath10k_snoc`), but throughput is severely throttled to **~15–17 Mbps download and ~12–30 Mbps upload**, regardless of whether connected to 2.4 GHz or 5 GHz (802.11ac).

## 2. Technical Root Cause Analysis
Inspecting `dmesg` and hardware descriptors on the tablet revealed:
```text
ath10k_snoc 18800000.wifi: qmi chip_id 0x320 chip_family 0x4001 board_id 0xff soc_id 0x40060000
ath10k_snoc 18800000.wifi: chan info: invalid frequency 0 (idx 41 out of bounds)
```

1. **Board Data File (BDF) Calibration Missing**:
   - `ath10k` queries `/usr/lib/firmware/ath10k/WCN3990/hw1.0/board-2.bin` for `bus=snoc,qmi-board-id=ff,qmi-chip-id=320`.
   - Upstream Arch's `linux-firmware-atheros` includes board calibration entries for ChromeOS devices (`GO_POMPOM`, `GO_LAZOR`) and other phones, but **none for Xiaomi Nabu**.
   - Because no matching calibration is found, the chip defaults to an uncalibrated failsafe mode that disables **AMPDU (A-MPDU) frame aggregation** and limits MCS transmission rates. Without AMPDU frame aggregation in 802.11ac, packet overhead caps throughput precisely at ~15 Mbps.
2. **Firmware Desynchronization**:
   - `firmware-5.bin` from upstream Arch enables `ATH10K_FW_FEATURE_SINGLE_CHAN_INFO_PER_CHANNEL`, which is incompatible with the Qualcomm DSP firmware `wlanmdsp.mbn` loaded by the modem DSP. This triggers the repeated `chan info: invalid frequency 0 (idx 41 out of bounds)` warnings and driver rate-control stalls.

## 3. Required Implementation in the Package Pipeline

When packaging `linux-firmware-xiaomi-nabu` and configuring the kernel:

### Step 1: Source the Matched WCN3990 Firmware & BDF
Extract or fetch the matched firmware set from postmarketOS's `firmware-xiaomi-nabu` / Pocketblue repository:
- `board-2.bin` (containing the calibrated BDF for SM8150 / Nabu)
- `wlanmdsp.mbn` (matched WLAN DSP blob)
- `firmware-5.bin` (matched driver firmware)

### Step 2: Install Destination in `PKGBUILD`
In `packages/linux-firmware-xiaomi-nabu/PKGBUILD`:
Install the matched files into:
```text
/usr/lib/firmware/ath10k/WCN3990/hw1.0/board-2.bin
/usr/lib/firmware/ath10k/WCN3990/hw1.0/wlanmdsp.mbn
/usr/lib/firmware/ath10k/WCN3990/hw1.0/firmware-5.bin
/usr/lib/firmware/qcom/sm8150/xiaomi/nabu/wlanmdsp.mbn
```

### Step 3: Protect Against Upstream Pacman Overwrites
To prevent future `pacman -Syu` runs of `linux-firmware-atheros` from overwriting these files:
In the tablet's `/etc/pacman.conf`, add:
```ini
NoExtract = usr/lib/firmware/ath10k/WCN3990/hw1.0/*
```

### Step 4: Driver Module Configuration
Ensure the package drops `/etc/modprobe.d/ath10k.conf`:
```ini
options ath10k_core cryptmode=0 frame_mode=1
```
*(Enforces hardware cryptographic acceleration and native 802.11 datapath frames).*
