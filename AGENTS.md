# whyred firmware agent guide

This repository owns the whyred (Xiaomi Redmi Note 5, SDM636) UEFI firmware.
It does not own the UniXNU core, the OS image or the board device tree; those
live in [N1709/UniXNU-whyred](https://github.com/N1709/UniXNU-whyred).

## Read first

| Task | Required reading |
| --- | --- |
| Every change | `Platforms/Xiaomi/whyredPkg/PORTING.md`, this file |
| Build | `Building.md`, `Resources/Configs/whyred.toml` |
| Memory | `Platforms/Xiaomi/whyredPkg/Library/MemoryMapLib/MemoryMapLib.c` |
| UniXNU integration | `UniXNU/docs/porting/uefi-firmware.md` in the UniXNU checkout |
| Hardware | `../UniXNU-whyred/board.toml`, `../UniXNU-whyred/dts/whyred.dts` |
| Verification | `UniXNU/docs/porting/bring-up.md`, `log-capture.md` |

## Rules

- Boot with `fastboot boot` only. Never flash boot, modem, persist or recovery,
  and never format `userdata`.
- Keep the FD at `0x9FC00000 + 0x300000`, the stack at `0x9FF90000` and the
  display reservation at `0x9D400000 + 0x02400000`. They are shared with the
  device repository and `MemoryMapLib.c`.
- whyred is SDM636, not SDM660. `PcdPlatformType = "LA"`, 1080x2160, GICv3.
- Do not copy another board's `Binaries/` vendor DXEs into this build. The
  panel XML, PMIC rails and charger config are board-specific.
- The default build is vendor-free; `Include/RAW.inc` stays empty until real
  whyred files are extracted.
- Keep `Resources/DTBs/whyred.dts` and `sdm660.dtsi` identical to the device
  repository sources, then regenerate `whyred.dtb` with `dtc`.
- Update `Platforms/Xiaomi/whyredPkg/PORTING.md` and `Status.md` with every
  platform change.

## Checks

```sh
dtc -I dts -O dtb -o Resources/DTBs/whyred.dtb -i Resources/DTBs Resources/DTBs/whyred.dts
./build_uefi.py -d whyred -r DEBUG
```

A build is only complete when `Build/whyredPkg/DEBUG_CLANGPDB/FV/SILICIUM_UEFI.fd`
exists and the FDF contains `UniXNU.inf`, `UniXNUDxe.inf`,
`UniXNURamDiskDxe.inf` and `DarwinBoot.inf`.

## Current boundary

Display comes from ABL through `SimpleFbDxe`; firmware storage, USB host,
charger, PMIC and ACPI are not implemented. The next milestones are the first
`fastboot boot` log at `0x0C170000` and then read-only eMMC enumeration.
