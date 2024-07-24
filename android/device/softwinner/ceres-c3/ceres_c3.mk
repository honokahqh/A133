# LOCAL_PATH MUST defined in Makefile top location
LOCAL_PATH := $(shell dirname $(lastword $(MAKEFILE_LIST)))

#32bit android,you should define TARGET_ARCH := arm
#64bit android,you should define TARGET_ARCH := arm64
TARGET_ARCH ?= arm64
ifeq ($(TARGET_ARCH),arm)
$(call inherit-product, device/softwinner/ceres-common/ceres_32_bit.mk)
else ifeq ($(TARGET_ARCH),arm64)
$(call inherit-product, device/softwinner/ceres-common/ceres_64_bit.mk)
endif
$(call inherit-product, device/softwinner/ceres-common/ceres-common.mk)
$(call inherit-product, $(LOCAL_PATH)/hal.mk)
$(call inherit-product, device/softwinner/common/pad.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/gsi_keys.mk)
$(call inherit-product, device/softwinner/common/custom/custom.mk)

ifneq ($(wildcard $(LOCAL_PATH)/modules/modules),)
PRODUCT_COPY_FILES += $(call find-copy-subdir-files,*,$(LOCAL_PATH)/modules/modules,$(TARGET_COPY_OUT_VENDOR)/modules)
endif

DEVICE_PACKAGE_OVERLAYS := $(LOCAL_PATH)/overlay \
                           $(DEVICE_PACKAGE_OVERLAYS)

# Disable APEX_LIBS_ABSENCE_CHECK
# We got offending entrie if enable check: libicui18n and libicuuc.
# Both are dependencies of libcedarx. We must fix the dependencies and then enable check.
DISABLE_APEX_LIBS_ABSENCE_CHECK := true

# build & split configs
PRODUCT_ENFORCE_RRO_TARGETS := framework-res
BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true
PRODUCT_FULL_TREBLE_OVERRIDE := true

PRODUCT_USE_DYNAMIC_PARTITIONS := true

ifeq ($(PRODUCT_USE_DYNAMIC_PARTITIONS),true)
PRODUCT_PACKAGES += \
    fastbootd \
    android.hardware.fastboot@1.0-impl
endif

PRODUCT_CPU_TYPE := A133

# all devices got ram size equal to or less than 1GB should be defined as low ram device.
# also we can get rid of the software limit, and fully use 2GB ram and config it as regular device.
CONFIG_LOW_RAM_DEVICE := true
ifeq ($(CONFIG_LOW_RAM_DEVICE),true)
    $(call inherit-product, $(LOCAL_PATH)/configs/go/go_base.mk)
    #$(call inherit-product, build/target/product/go_defaults.mk)
    # use special go config
    $(call inherit-product, device/softwinner/common/go_common.mk)
    $(call inherit-product, device/softwinner/common/mainline_go.mk)

    # flattened apex. Go device use flattened apex for the consider of performance
    TARGET_FLATTEN_APEX := true

    DEVICE_PACKAGE_OVERLAYS := $(LOCAL_PATH)/overlay_go \
                               $(DEVICE_PACKAGE_OVERLAYS)
    # Strip the local variable table and the local variable type table to reduce
    # the size of the system image. This has no bearing on stack traces, but will
    # leave less information available via JDWP.
    PRODUCT_MINIMIZE_JAVA_DEBUG_INFO := true

    # Do not generate libartd.
    PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD := false

    # Enable DM file preopting to reduce first boot time
    PRODUCT_DEX_PREOPT_GENERATE_DM_FILES :=true
    PRODUCT_DEX_PREOPT_DEFAULT_COMPILER_FILTER := verify

    # Reduces GC frequency of foreground apps by 50% (not recommanded for 512M devices)
    PRODUCT_SYSTEM_DEFAULT_PROPERTIES += dalvik.vm.foreground-heap-growth-multiplier=2.0

    # launcher
    PRODUCT_PACKAGES += Launcher3QuickStepGo

    # include gms package for go
    $(call inherit-product-if-exists, vendor/partner_gms/products/gms_go-mandatory.mk)

    # limit dex2oat threads to improve thermals
    PRODUCT_PROPERTY_OVERRIDES += \
        dalvik.vm.boot-dex2oat-threads=4 \
        dalvik.vm.dex2oat-threads=3 \
        dalvik.vm.image-dex2oat-threads=4

    PRODUCT_PROPERTY_OVERRIDES += \
        dalvik.vm.dex2oat-flags=--no-watch-dog \
        dalvik.vm.jit.codecachesize=0

    PRODUCT_PROPERTY_OVERRIDES += \
        pm.dexopt.boot=extract \
        dalvik.vm.heapstartsize=8m \
        dalvik.vm.heapsize=256m \
        dalvik.vm.heaptargetutilization=0.75 \
        dalvik.vm.heapminfree=512k \
        dalvik.vm.heapmaxfree=8m

   PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
        dalvik.vm.madvise-random=true

    # camera hal: Q Regular version must use camera hal v3
    USE_CAMERA_HAL_3_4 := true

else # ifeq ($(CONFIG_LOW_RAM_DEVICE),true)
    $(call inherit-product, build/target/product/full_base.mk)
    $(call inherit-product, device/softwinner/common/mainline.mk)

    # non-go device use updatable apex
    $(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

    # launcher
    PRODUCT_PACKAGES += Launcher3QuickStep

    # include gms package
    $(call inherit-product-if-exists, vendor/partner_gms/products/gms-mandatory.mk)

    PRODUCT_PROPERTY_OVERRIDES += \
        dalvik.vm.heapstartsize=8m \
        dalvik.vm.heapgrowthlimit=256m \
        dalvik.vm.heapsize=512m \
        dalvik.vm.heaptargetutilization=0.75 \
        dalvik.vm.heapminfree=512k \
        dalvik.vm.heapmaxfree=8m
    # camera hal: P Regular version must use camera hal v3
    USE_CAMERA_HAL_3_4 := true

endif# ifeq ($(CONFIG_LOW_RAM_DEVICE),true)

# enable property split
PRODUCT_COMPATIBLE_PROPERTY_OVERRIDE := true

# set product shipping(first) api level
PRODUCT_SHIPPING_API_LEVEL := 29

# secure config
BOARD_HAS_SECURE_OS ?= false

# drm config
BOARD_WIDEVINE_OEMCRYPTO_LEVEL := 3

# dm-verity relative
#$(call inherit-product, build/target/product/verity.mk)
# PRODUCT_SUPPORTS_BOOT_SIGNER must be false,otherwise error will be find when boota check boot partition
#PRODUCT_SUPPORTS_BOOT_SIGNER := false
#PRODUCT_SUPPORTS_VERITY_FEC := false
#PRODUCT_SYSTEM_VERITY_PARTITION := /dev/block/by-name/system
#PRODUCT_VENDOR_VERITY_PARTITION := /dev/block/by-name/vendor
#PRODUCT_PACKAGES += \
#    slideshow \
#    verity_warning_images

#set speaker project(true: double speaker, false: single speaker)
PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.spk_dul.used=true


PRODUCT_PACKAGES += \
    SoundRecorder

#PRODUCT_PACKAGES += AllwinnerGmsIntegration

############################### 3G Dongle Support ###############################
# Radio Packages and Configuration Flie
$(call inherit-product-if-exists, vendor/aw/public/prebuild/lib/librild/radio_common.mk)

PRODUCT_FSTAB := fstab.sun50iw10p1
ifneq ($(BOARD_HAS_SECURE_OS), true)
    PRODUCT_FSTAB := fstab.sun50iw10p1.noverify
    $(shell cp $(LOCAL_PATH)/fstab.sun50iw10p1 $(LOCAL_PATH)/$(PRODUCT_FSTAB))
    $(shell sed -i 's/,avb=.*$$//g' $(LOCAL_PATH)/$(PRODUCT_FSTAB))
    $(shell sed -i 's/,fileencryption=.*$$//g' $(LOCAL_PATH)/$(PRODUCT_FSTAB))
endif
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/$(PRODUCT_FSTAB):$(TARGET_COPY_OUT_RAMDISK)/fstab.sun50iw10p1 \
    $(LOCAL_PATH)/$(PRODUCT_FSTAB):$(TARGET_COPY_OUT_VENDOR)/etc/fstab.sun50iw10p1

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/kernel:kernel \
    $(LOCAL_PATH)/init.device.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.device.rc \
    $(LOCAL_PATH)/init.recovery.sun50iw10p1.rc:root/init.recovery.sun50iw10p1.rc \

PRODUCT_COPY_FILES += \
    device/softwinner/common/config/tablet_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/tablet_core_hardware.xml \
    $(LOCAL_PATH)/configs/sensor_feature.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/sensor_feature.xml \
    device/softwinner/common/config/android.hardware.location.network.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.hardware.location.network.xml \
    frameworks/native/data/etc/android.hardware.camera.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.software.verified_boot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.verified_boot.xml \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.sensor.accelerometer.xml \
    $(LOCAL_PATH)/language/ko_2018030706.zip:/product/usr/share/ime/google/d3_lms/ko_2018030706.zip \
    $(LOCAL_PATH)/language/mozc.data:/product/usr/share/ime/google/d3_lms/mozc.data \
    $(LOCAL_PATH)/language/zh_CN_2018030706.zip:/product/usr/share/ime/google/d3_lms/zh_CN_2018030706.zip

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/camera.cfg:$(TARGET_COPY_OUT_VENDOR)/etc/camera.cfg \
    $(LOCAL_PATH)/configs/media_profiles.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml \
    $(LOCAL_PATH)/configs/media_codecs_performance.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_performance.xml \
    $(LOCAL_PATH)/configs/media_codecs_c2.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/media_codecs.xml \
    $(LOCAL_PATH)/configs/gsensor.cfg:$(TARGET_COPY_OUT_VENDOR)/etc/gsensor.cfg \
    device/softwinner/common/config/awbms_config:$(TARGET_COPY_OUT_VENDOR)/etc/awbms_config \

PRODUCT_COPY_FILES += \
    hardware/aw/camera/1_0/libstd/libstdc++.so:$(TARGET_COPY_OUT_VENDOR)/lib/libstdc++.so

#camera config for camera detector
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/hawkview/sensor_list_cfg.ini:vendor/etc/hawkview/sensor_list_cfg.ini

# audio
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio_mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_mixer_paths.xml

# bootanimation
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/media/bootanimation.zip:system/media/bootanimation.zip

# preferred activity
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/preferred-apps/custom.xml:system/etc/preferred-apps/custom.xml

#lmkd whitelist
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/lmkd_whitelist:$(TARGET_COPY_OUT_SYSTEM)/etc/lmkd_whitelist

PRODUCT_PROPERTY_OVERRIDES += \
    ro.frp.pst=/dev/block/by-name/frp

ifneq (,$(filter userdebug eng,$(TARGET_BUILD_VARIANT)))
PRODUCT_DEBUG := true

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.sys.usb.config=adb \
    ro.adb.secure=0

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.sys.dis_app_animation=true
else
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.adb.secure=1
endif

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160

#language pack
PRODUCT_PRODUCT_PROPERTIES  += \
    ro.com.google.ime.system_lm_dir= /product/usr/share/ime/google/d3_lms

PRODUCT_PROPERTY_OVERRIDES += \
    ro.control_privapp_permissions=enforce

# set primary display orientation to 270
PRODUCT_PROPERTY_OVERRIDES += \
    ro.surface_flinger.primary_display_orientation=ORIENTATION_0 \

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.minui.default_rotation=ROTATION_LEFT \
    ro.recovery.ui.touch_high_threshold=60

PRODUCT_PROPERTY_OVERRIDES += \
    ro.camera.enableLazyHal=true

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.primary_display.user_rotation=0 \
    ro.input_flinger.primary_touch.rotation=0

# if display width < height, maybe qq camera is not match
# we can set the property for qq.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.qq.camera.sensor=3 \

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.app.picsart.rotation=0 \

PRODUCT_PROPERTY_OVERRIDES += \
    ro.vendor.sf.rotation=0

PRODUCT_PROPERTY_OVERRIDES += \
    ro.lmk.downgrade_pressure=80 \
    ro.lmk.upgrade_pressure=35 \
    ro.lmk.use_minfree_levels=false \
    ro.lmk.kill_heaviest_task=false \
    ro.lmk.use_new_strategy=false

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.sys.timezone=Asia/Shanghai \
    persist.sys.country=CN \
    persist.sys.language=zh

PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.locale=zh-CN

# stoarge
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.fw.force_adoptable=true

#booevent true=enable bootevent,false=disable bootevent
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += persist.sys.bootevent=true

# for adiantum encryption
PRODUCT_PROPERTY_OVERRIDES += \
    ro.crypto.volume.contents_mode=aes-256-xts \
    ro.crypto.volume.filenames_mode=aes-256-cts

# display
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.display.smart_backlight=1 \
    persist.display.enhance_mode=0 \

#PRODUCT_ROTATION := 90

PRODUCT_HAS_UVC_CAMERA := true
ifeq ($(PRODUCT_HAS_UVC_CAMERA),true)
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.camera.uvcfacing=back

PRODUCT_COPY_FILES += \
    device/softwinner/common/config/external_camera_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/external_camera_config.xml
endif

PRODUCT_CHARACTERISTICS := tablet

PRODUCT_AAPT_CONFIG := mdpi xlarge hdpi xhdpi large
PRODUCT_AAPT_PREF_CONFIG := mdpi

PRODUCT_BRAND := Allwinner
PRODUCT_NAME := ceres_c3
PRODUCT_DEVICE := ceres-c3
# PRODUCT_BOARD must equals the board name in kernel
PRODUCT_BOARD := c3
PRODUCT_MODEL := QUAD-CORE A133 c3
PRODUCT_MANUFACTURER := Allwinner

PRODUCT_PROPERTY_OVERRIDES += \
    ro.com.google.clientidbase=android-allwinner

$(call inherit-product-if-exists, vendor/aw/public/tool.mk)
