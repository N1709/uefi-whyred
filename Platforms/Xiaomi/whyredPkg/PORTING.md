# whyred platform port

`whyredPkg` is the Xiaomi Redmi Note 5 (whyred, SDM636) platform for the
UniXNU firmware tree. It is derived from `UniXNU/uefi-sheng` at
`66421cb7bb5694843aec8de1ca3d1de4c20cca38` and keeps the sheng UniXNU module
integration.

## Base choice

The tree already contained two SDM660/SDM636 platforms:

| Package | SoC | FD base/size | Stack | Framebuffer | Memory map |
| --- | --- | --- | --- | --- | --- |
| `lavenderPkg` | SDM660 | `0x9FC00000 + 0x300000` | `0x9FF90000` | 1080x2340 | matches whyred |
| `nitrogenPkg` | SDM636 | `0x9FC00000 + 0x300000` | `0x9FF90000` | 1080x2160 | matches whyred byte for byte |
| `whyredPkg` | SDM636 | `0x9FC00000 + 0x300000` | `0x9FF90000` | 1080x2160 | same as nitrogen |

`nitrogenPkg` (Mi Max 3, SDM636) is used as the structural base for the DSC,
FDF, `MemoryMapLib` and `ConfigurationMapLib`. Its memory map is identical to
`lavenderPkg` apart from whitespace, and it is the same SoC family and the same
1080x2160 panel resolution as whyred. The whyred identity, DTB, PCDs and
UniXNU integration are board-specific.

## Display

whyred needs no vendor display driver for the first milestone. ABL initializes
the DSI panel and leaves a contiguous framebuffer at `0x9D400000`
(`0x02400000` bytes). `SiliciumPkg/Drivers/SimpleFbDxe` publishes a GOP over
that buffer using `PcdFrameBufferWidth = 1080`,
`PcdFrameBufferHeight = 2160` and `PcdFrameBufferColorDepth = 32`. This is the
same approach the previous whyred XNU work and the independent
`whyred-pve-uefi` port use.

The stock whyred `DisplayDxe`, its panel XML and the I2C/TLMM/PMIC DXEs it needs
are not extracted yet. Do not point `USE_CUSTOM_DISPLAY_DRIVER` at another
board's `Binaries/` directory: the panel init sequence and PMIC rails differ.

## Vendor drivers

This build is vendor-free by design:

- no `Binaries/<device>` INF is referenced;
- no raw vendor file is included (`Include/RAW.inc` is empty);
- `PcdBuildXblHobs` is `FALSE`, because there is no stock DXE stack to consume
  the scheduler/FV HOBs and scanning the leftover XBL window stalled sheng's
  vendor-free build;
- USB host, eMMC/SD, charger and PMIC drivers are therefore absent from the
  first image.

UniXNU does not need firmware block IO to boot: the payload volume and initrd
are loaded from the boot image and published by `UniXNURamDiskDxe`, DiskIo,
PartitionDxe and Fat. The XNU storage driver is a separate component. Vendor
DXEs can be added later, after a whyred firmware package is staged and its
panel/PMIC wiring is checked.

## Memory

`MemoryMapLib.c` reserves the regions whyred's bootloader and the previous XNU
work used:

| Region | Base | Size |
| --- | --- | --- |
| Kernel | `0x80000000` | `0x05800000` |
| SMEM | `0x86000000` | `0x00200000` |
| DXE Heap | `0x94000000` | `0x09400000` |
| Display Reserved | `0x9D400000` | `0x02400000` |
| FV Region | `0x9F800000` | `0x00200000` |
| ABOOT FV | `0x9FA00000` | `0x00200000` |
| UEFI FD | `0x9FC00000` | `0x00300000` |
| SEC Heap | `0x9FF00000` | `0x0008C000` |
| MMU PageTables | `0x9FF8D000` | `0x00003000` |
| UEFI Stack | `0x9FF90000` | `0x00040000` |

`WhyredBootMemoryDxe` reads the firmware FDT that the boot shim passes in `x0`.
It adds the `device_type = "memory"` ranges to the GCD, subtracts
`/reserved-memory`, and only touches ranges the GCD still reports as
non-existent. It adds at most 1 GiB below 4 GiB, which is enough for the
payload and leaves the high bank at `0x100000000` alone.

The firmware DTB is `Resources/DTBs/whyred.dtb` (2788 bytes). It declares the
low 2 GiB bank at `0x80000000` and the splash reservation
`0x9D400000 + 0x02400000`. It is compiled from `whyred.dts` +
`sdm660.dtsi`, which are copies of the device repository sources and must stay
identical.

## UniXNU integration

The UniXNU block from `shengPkg` is kept:

- DSC: `UniXNUPkg/Application/UniXNU/UniXNU.inf`,
  `UniXNUPkg/Driver/UniXNUDxe/UniXNUDxe.inf`,
  `UniXNUPkg/Driver/UniXNURamDiskDxe/UniXNURamDiskDxe.inf`,
  `DarwinBootPkg/Driver/DarwinBoot.inf`, `UniXNULib` and `FdtLib`.
- FDF: the same modules plus `DiskIoDxe`, `PartitionDxe`, `Fat` and
  `EnglishDxe`.
- `DarwinBoot` is built into the firmware because a driver loaded from a
  volume is refused by the image verification.

## Build

```sh
./setup_env.sh -p apt        # or install the same tools another way
./build_uefi.py -d whyred -r RELEASE
```

Output:

```text
Build/whyredPkg/RELEASE_CLANGPDB/FV/SILICIUM_UEFI.fd
Mu-whyred.img
```

`Resources/Configs/whyred.toml` fixes the FD at `0x9FC00000 + 0x300000` and
appends the whyred DTB. The image must be booted with

```sh
fastboot boot Mu-whyred.img
```

Never flash boot, modem, persist or recovery, and never format `userdata`.

## Verification order

1. FD base/size match `Resources/Configs/whyred.toml`, `MemoryMapLib.c` and
   the UniXNU device repository `board.toml`.
2. Serial console on BLSP1 UART2 at `0x0C170000`, 115200 8n1, prints the
   SEC/PEI/DXE log.
3. `WHYREDMEM: added ... bytes of system memory` appears.
4. `SimpleFbDxe` publishes a GOP and the UniXNU menu is visible.
5. `UNIXNURAMDISK: initrd block device` appears.
6. `DarwinBoot` starts XNU and the ADT matches `board.toml`.

## Still missing

- stock whyred `DisplayDxe`, panel XML, I2C/TLMM/PMIC DXEs;
- stock whyred `SecParti.cfg`, charger config and battery provision;
- a platform ACPI table (`whyred/AcpiTables.inf`);
- eMMC/SD, USB host and charger drivers;
- on-device verification of the first FD.
