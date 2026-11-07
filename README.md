# uefi-whyred

UEFI firmware for the Xiaomi Redmi Note 5 (whyred, Qualcomm SDM636), built on
Project Silicium / Project Mu and integrated with UniXNU.

This repository is a fork of [UniXNU/uefi-sheng](https://github.com/UniXNU/uefi-sheng)
at `66421cb7bb5694843aec8de1ca3d1de4c20cca38`. It keeps the sheng UniXNU,
DarwinBoot, RamDisk and FAT integration and replaces the SM8550 platform with
`Platforms/Xiaomi/whyredPkg`.

- [Build instructions](Building.md)
- [Platform details and limits](Platforms/Xiaomi/whyredPkg/PORTING.md)
- [Platform status](Status.md)
- [Device repository](https://github.com/N1709/UniXNU-whyred)
- [Firmware integration](https://unixnu.com/porting/uefi-firmware)

## Current state

The first whyred image is vendor-free:

- `SimpleFbDxe` publishes a GOP over the framebuffer ABL already scans out at
  `0x9D400000` (1080x2160);
- `WhyredBootMemoryDxe` adds the FDT memory ranges to the GCD;
- `UniXNURamDiskDxe`, DiskIo, PartitionDxe and Fat publish the payload volume;
- `DarwinBoot` is part of the firmware.

There is no whyred vendor `DisplayDxe`, eMMC/USB/charger stack or ACPI table
yet. See `Platforms/Xiaomi/whyredPkg/PORTING.md` for the exact gaps.

## Build

```sh
./setup_env.sh -p apt
./build_uefi.py -d whyred -r RELEASE
```

The output is `Build/whyredPkg/RELEASE_CLANGPDB/FV/SILICIUM_UEFI.fd` and the
Android boot image `Mu-whyred.img`. Boot it with:

```sh
fastboot boot Mu-whyred.img
```

Never flash boot, modem, persist or recovery, and never format `userdata`.
The device must always be recoverable through `fastboot boot`.

## Credits

[Microsoft](https://github.com/microsoft/) for [Project Mu](https://microsoft.github.io/mu/),
[WOA-Project](https://github.com/WOA-Project/) for `mu_andromeda_platforms`,
[Project Aloha](https://github.com/Project-Aloha/) for `mu_aloha_platforms`,
and [Project Silicium](https://github.com/Project-Silicium) for the Mu-Silicium
tree and Device-Binaries.

## License

All code except drivers in `GPLDrivers`, `GPLApplications` and `GPLLibrary`
directories is licensed under BSD-2-Clause. GPL drivers are licensed under
GPLv2 or later.
