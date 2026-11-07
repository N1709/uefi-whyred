##
#  Copyright (c) 2011 - 2022, ARM Limited. All rights reserved.
#  Copyright (c) 2014, Linaro Limited. All rights reserved.
#  Copyright (c) 2015 - 2020, Intel Corporation. All rights reserved.
#  Copyright (c) 2018, Bingxing Wang. All rights reserved.
#  Copyright (c) Microsoft Corporation.
#
#  SPDX-License-Identifier: BSD-2-Clause-Patent
##

################################################################################
#
# Defines Section - statements that will be processed to create a Makefile.
#
################################################################################
[Defines]
  PLATFORM_NAME                  = whyred
  PLATFORM_GUID                  = DCA174E0-A9FD-4258-A8E0-C2C4E9D816FD
  PLATFORM_VERSION               = 0.1
  DSC_SPECIFICATION              = 0x00010005
  OUTPUT_DIRECTORY               = Build/whyredPkg
  SUPPORTED_ARCHITECTURES        = AARCH64
  BUILD_TARGETS                  = RELEASE|DEBUG
  SKUID_IDENTIFIER               = DEFAULT
  FLASH_DEFINITION               = whyredPkg/whyred.fdf

  #
  # 0 = SimpleFbDxe publishes a GOP over the framebuffer ABL has already
  #     initialized at 0x9D400000. This is the whyred default: the panel is
  #     initialized before UEFI starts and does not need a vendor DXE.
  # 1 = load the stock DisplayDxe chain. There is no whyred vendor binary yet;
  #     see PORTING.md before switching this on.
  #
  USE_CUSTOM_DISPLAY_DRIVER      = 0

!include BlackboltPkg/BlackboltPkg.dsc.inc

[PcdsFixedAtBuild]
  #
  # DDR Memory
  #
  # whyred low bank: 0x80000000 + 2 GiB on 3/4/6 GB variants. The high bank
  # starts at 0x100000000 and is not mapped by this firmware.
  #
  gArmTokenSpaceGuid.PcdSystemMemoryBase|0x80000000

  #
  # UEFI Stack
  #
  gArmPlatformTokenSpaceGuid.PcdCPUCoresStackBase|0x9FF90000
  gArmPlatformTokenSpaceGuid.PcdCPUCorePrimaryStackSize|0x40000

  #
  # SMBIOS
  #
  gSiliciumPkgTokenSpaceGuid.PcdSmbiosSystemManufacturer|"Xiaomi"
  gSiliciumPkgTokenSpaceGuid.PcdSmbiosSystemModel|"Redmi Note 5"
  gSiliciumPkgTokenSpaceGuid.PcdSmbiosSystemRetailModel|"whyred"
  gSiliciumPkgTokenSpaceGuid.PcdSmbiosSystemRetailSku|"Redmi_Note_5_whyred"
  gSiliciumPkgTokenSpaceGuid.PcdSmbiosSystemBoardModel|"Redmi Note 5"

  #
  # Simple Frame Buffer
  #
  # 1080x2160 from the vendor DSI panel entries. WhyredFbDxe/SimpleFbDxe
  # assumes the ABL scan-out stride is width * 4 bytes (4320), the same
  # assumption the previous whyred work verified.
  #
  gSiliciumPkgTokenSpaceGuid.PcdFrameBufferWidth|1080
  gSiliciumPkgTokenSpaceGuid.PcdFrameBufferHeight|2160
  gSiliciumPkgTokenSpaceGuid.PcdFrameBufferColorDepth|32

  #
  # Platform PEI
  #
  gQcomPkgTokenSpaceGuid.PcdPlatformType|"LA"

  #
  # This build has no stock vendor DXE stack. PlatformPeim must not scan the
  # leftover XBL FD window or install the stock scheduler protocol; whyred
  # memory is described by the FDT through WhyredBootMemoryDxe instead.
  #
  gQcomPkgTokenSpaceGuid.PcdBuildXblHobs|FALSE

[LibraryClasses]
  #
  # Memory Libraries
  #
  MemoryMapLib|whyredPkg/Library/MemoryMapLib/MemoryMapLib.inf

  #
  # QCOM Libraries
  #
  ConfigurationMapLib|whyredPkg/Library/ConfigurationMapLib/ConfigurationMapLib.inf

  #
  # UniXNU Libraries
  #
  UniXNULib|UniXNUPkg/Library/UniXNULib/UniXNULib.inf
  FdtLib|MdePkg/Library/BaseFdtLib/BaseFdtLib.inf

[Components]
  #
  # Whyred platform glue
  #
  whyredPkg/Drivers/WhyredBootMemoryDxe/WhyredBootMemoryDxe.inf

  #
  # UniXNU application and payload handoff
  #
  UniXNUPkg/Application/UniXNU/UniXNU.inf
  UniXNUPkg/Driver/UniXNUDxe/UniXNUDxe.inf
  UniXNUPkg/Driver/UniXNURamDiskDxe/UniXNURamDiskDxe.inf
  DarwinBootPkg/Driver/DarwinBoot.inf
