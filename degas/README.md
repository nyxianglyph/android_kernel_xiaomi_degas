# Halium kernel for the Xiaomi 14T (`degas`)

GKI `android14-6.1` kernel with the UBports Halium patches, for running Ubuntu
Touch (and, next, Sailfish OS) on the Xiaomi 14T (MediaTek Dimensity 8300-Ultra
`mt6897`). It is binary compatible with the stock vendor modules, so only the
kernel `Image` is replaced; all 456 stock modules from `vendor_boot` and
`vendor_dlkm` load unchanged.

## Base

| | |
|---|---|
| Upstream | Android Common Kernel `android14-6.1`, commit `78a0a76cd7b7` (6.1.157, `android14-6.1-2025-12`) |
| Why this commit | It is what the stock HyperOS `OS3.0.305.0.WNEIDXM` GKI was built from (CI build `ab15497637`, manifest in `degas/manifest_15497637.xml`) |
| History | The first commit imports that upstream tree as one commit; the commits after it are the Halium/degas changes with their original authors |
| Halium patches | The 22 own commits of UBports `android14-6.1-halium` (6.1.145), rebased onto 6.1.157 |
| degas changes | `gki_quirks` entry for `mali_kbase_mt6897_r44`, `degas_androidtest.config`, this folder |

## ABI (KMI) compatibility

Plain `halium.config` on the stock source breaks the ABI: `CONFIG_SYSVIPC`
adds fields to `task_struct` and shifts `android_vendor_data1` by 24 bytes
(1707 symbol CRC mismatches, 434 broken modules). The UBports patch
`(halium) GKI: use Android ABI padding for SYSVIPC task_struct fields` puts
those fields into `ANDROID_KABI_RESERVE` slots instead.

Result of this tree (`degas/kmi/crc_check.py` against the CRC table of all
stock modules, `degas/kmi/all_versions.txt`):

```
symbols expected: 4870
  provided by this build: 2709
    CRC match:    2709
    CRC MISMATCH: 0
modules with a mismatching symbol: 0
```

Struct layouts were also checked with `pahole`: `task_struct` is 4800 bytes
with identical vendor/OEM data offsets. Do not rely on CRCs alone.

## Build

```bash
# from the root of a Kleaf checkout of degas/manifest_15497637.xml, this tree as common/
common/degas/build.sh ut            # Ubuntu Touch / Sailfish (AppArmor first)
common/degas/build.sh androidtest   # SELinux first: boots HyperOS and TWRP
```

Package `arch/arm64/boot/Image` into a boot image v4 and add the stock AVB
footer props, or MiTEE KeyMint rejects the metadata key
(`-33 INVALID_KEY_BLOB`, "unable to mount storage" in TWRP):

```bash
avbtool add_hash_footer --image boot.img --partition_name boot --partition_size 67108864 \
  --prop com.android.build.boot.os_version:14 \
  --prop com.android.build.boot.security_patch:2026-08-01 \
  --prop com.android.build.boot.fingerprint:Xiaomi/hal_mgvi_64_armv82_mt6897_global/mgvi_64_armv82:14/UP1A.231005.007/OS3.0.305.0.WNEIDXM:user/release-keys
```

## Tested

| | |
|---|---|
| HyperOS on this kernel (`androidtest`) | ✅ boots, SELinux enforcing, 468 modules, Wi-Fi, display, audio, both SIMs on LTE |
| Ubuntu Touch 24.04 (`ut`) | ✅ boots to Lomiri, see the Ubuntu Touch adaptation repo |
| `ut` flavour with Android/TWRP | ❌ Android init needs SELinux as the first major LSM |

The 9 modules that do not load (`bluetooth`, `btbcm`, `btqca`, `btsdio`,
`hci_uart`, `hidp`, `rfcomm`, `rfkill`, `nfc`) are built in by `halium.config`.
