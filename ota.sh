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

# 开始构建
echo "Starting build with 16 parallel jobs..."
make -j16

# 制作ota包
pack4dist

# 打包
echo "Packing..."
cp /home/szbaijie/newboard/android/out/target/product/ceres-c3/ceres_c3-full_ota-eng.szbaijie.zip /mnt/hgfs/share/
echo "Build process completed."

