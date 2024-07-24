#!/bin/bash

# 跳转到 android 目录
cd android

# 设置构建环境
source build/envsetup.sh

# 自动选择 `lunch` 选项
lunch_option="ceres_c3-userdebug"
lunch_number="41"

echo "Running lunch command..."
lunch ${lunch_option}

# 提取 BSP
echo "Extracting BSP..."
extract-bsp

# 开始构建
echo "Starting build with 16 parallel jobs..."
make -j16

# 打包
echo "Packing..."
pack
cp ~/newboard/longan/out/a133_android10_c3_uart0.img /mnt/hgfs/share/

echo "Build process completed."
