### Answer files directory

This directory contains answer files (or unattend files) template for automatic Windows installation and configuration.
There are following files:
   1. autounattend.xml - configure Windows installation process. The next field should be replaced:
      - @WINDOWS_IMAGE_NAME@ - Windows image name from `install.wim` file. It can be received using `wimlib-imagex info install.wim` command
      - @PRODUCT_KEY@ - Product key for corresponding Windows image

      There are two autounattend file templates:
      - autounattend.xml.uefi.in - for UEFI boot with GUID Partition Table (GPT)
      - autounattend.xml.bios.in - for BIOS boot with Master Boot Record (MBR) partition table
   2. unattend.xml - configure Windows OOBE process. The next field should be replaced:
      - @HOST_TYPE@ - Type of VM: `studio` or `client`
