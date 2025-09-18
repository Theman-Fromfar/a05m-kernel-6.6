#!/bin/bash
cd kernel-6.6
curl -LSs "https://raw.githubusercontent.com/rsuntk/KernelSU/main/kernel/setup.sh" | bash -s main

echo ""
	echo -e "Host Arch: `uname -m`"
	echo -e "Host Kernel: `uname -r`"
	echo -e "Host gnumake: `make -v | grep -e "GNU Make"`"
	echo ""
	echo -e "Linux version: `make kernelversion`"
	echo -e "Kernel builder user: `whoami`"
	echo -e "Kernel builder host: `hostname`"
	echo -e "Build date: `date`"
	echo ""

 sleep 5
cd ..

cd kernel
python kernel_device_modules-6.6/scripts/gen_build_config.py --kernel-defconfig mediatek-bazel_defconfig --kernel-defconfig-overlays "mt6768_overlay.config S96818AA1.config S96818AA1_debug.config kernelsu.config" --kernel-build-config-overlays "" -m user -o ../out/target/product/a05m/obj/KERNEL_OBJ/build.config


export DEVICE_MODULES_DIR="kernel_device_modules-6.6"
export BUILD_CONFIG="../out/target/product/a05m/obj/KERNEL_OBJ/build.config"
export OUT_DIR="../out/target/product/a05m/obj/KLEAF_OBJ"
export DIST_DIR="../out/target/product/a05m/obj/KLEAF_OBJ/dist"
export DEFCONFIG_OVERLAYS="mt6768_overlay.config S96818AA1.config S96818AA1_debug.config"
export PROJECT="mgk_64_k66"
export MODE="user"
export SANDBOX="0"

./kernel_device_modules-6.6/build.sh

cd ..

ANYKERNEL_DIR="$(pwd)/AnyKernel3"
ANYKERNEL_FILE="$(pwd)/AnyKernel3/anykernel.sh"
KERNEL_IMAGE="$(pwd)/out/target/product/a05m/obj/KLEAF_OBJ/dist/kernel_device_modules-6.6/mgk_64_k66_kernel_aarch64.user/Image"
ZIPNAME="a05m-6.6-kernel"
INFO_FILE="$(pwd)/kernel/kernel_device_modules-6.6/kernel/configs/mt6768_overlay.config"
KERNEL_VERSION_NAME=$(grep "CONFIG_LOCALVERSION=" "$INFO_FILE" | sed -n 's/.*CONFIG_LOCALVERSION="\([^"]*\)".*/\1/p')
sed -i "s/kernel.string=.*/kernel.string=\"a05m-${KERNEL_VERSION_NAME}-kernel\"/" "$ANYKERNEL_FILE"

set -e

if [ ! -f "$KERNEL_IMAGE" ]; then
    echo "Error: Kernel image '$KERNEL_IMAGE' not found!"
    exit 1
fi

if [ ! -d "$ANYKERNEL_DIR" ]; then
    echo "Error: Directory '$ANYKERNEL_DIR' not found!"
    exit 1
fi

echo "Kernel image and AnyKernel3 directory found"

cp "$KERNEL_IMAGE" "$ANYKERNEL_DIR/"
TIMESTAMP=$(date +"(%Y.%m.%d.%H.%M.%S)")
FINAL_ZIP_NAME="${ZIPNAME}-${KERNEL_VERSION_NAME}-${TIMESTAMP}.zip"
echo "Creating zip file: $FINAL_ZIP_NAME"

(cd "$ANYKERNEL_DIR" && zip -r9 "../$FINAL_ZIP_NAME" ./*)

echo " "
echo "✅ Done! Flashable zip created successfully"
echo "File: $FINAL_ZIP_NAME"
