### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers & GitHub @ Xiaomichael&cctv18

### AnyKernel setup
# global properties
properties() { '
kernel.string=AnyKernel3 by KernelSU Developers | Build by cctv18
do.devicecheck=0
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
## boot shell variables
BLOCK=boot
IS_SLOT_DEVICE=auto
RAMDISK_COMPRESSION=auto
PATCH_VBMETA_FLAG=auto
NO_MAGISK_CHECK=1

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh

ui_print "内核构建者: Coolapk@cctv18"

# Resolving occasional file system I/O latency issues which may cause binary execution exceptions
sync
sleep 0.5
chmod -R 755 $AKHOME/tools

# boot install
split_boot
if [ -f "split_img/ramdisk.cpio" ]; then
    unpack_ramdisk
    write_boot
else
    flash_boot
fi
## end boot install
# 优先选择模块路径
if [ -f "$AKHOME/zram.zip" ]; then
    MODULE_PATH="$AKHOME/zram.zip"
    KSUD_PATH="/data/adb/ksud"
    if [ -f "$KSUD_PATH" ]; then
        ui_print "Installing zram Module..."
        /data/adb/ksud module install "$MODULE_PATH"
        ui_print "Installation Complete!"
    else
        ui_print "KSUD Not Found, skipping installation..."
    fi
else
    ui_print "ZRAM module Not Found, skipping ZRAM module installation..."
fi
if [ -f "$AKHOME/kpn.zip" ]; then
    MODULE_PATH="$AKHOME/kpn.zip"
    KSUD_PATH="/data/adb/ksud"
    if [ -f "$KSUD_PATH" ]; then
        ui_print "Installing KP-N Module..."
        /data/adb/ksud module install "$MODULE_PATH"
        ui_print "Installation Complete!"
    else
        ui_print "KSUD Not Found, skipping installation..."
    fi
else
    ui_print "KP-N module Not Found, skipping KP-N module installation..."
fi

## 防砖保护 (abslot-tool): 刷入时先恢复 A/B 元数据(-r: 当前槽 15/tries7,
## 另一槽 14/tries7), 再对当前槽清 successful_boot 并装填重试次数(-p)。
## 恢复步骤避免上次保护期消耗的 tries 累积归零, 导致误换槽或另一槽兜底失效;
## 新内核起不来时 preloader 自动切换到另一槽位, 免拆机救砖。
## abtool 二进制由 peek 构建工作流放进 tools/ (chmod -R 755 已统一赋权)。
if [ -f "$AKHOME/tools/abtool" ]; then
    AB_SLOT=$(getprop ro.boot.slot_suffix 2>/dev/null)
    [ -z "$AB_SLOT" ] && AB_SLOT=$(grep -o 'androidboot.slot_suffix=_[ab]' /proc/cmdline | head -1 | cut -d= -f2)
    [ -z "$AB_SLOT" ] && AB_SLOT=$(grep -o 'androidboot.slot=[ab]' /proc/cmdline | head -1 | cut -d= -f2)
    case "$AB_SLOT" in
        _a|a) AB_N=0 ;;
        _b|b) AB_N=1 ;;
        *) AB_N= ;;
    esac
    if [ -n "$AB_N" ]; then
        ui_print "防砖保护: 恢复 A/B 元数据并对当前槽位($AB_SLOT)启用自动换槽..."
        "$AKHOME/tools/abtool" -r "$AB_N"
        if "$AKHOME/tools/abtool" -p "$AB_N"; then
            "$AKHOME/tools/abtool" -d | while IFS= read -r AB_L; do ui_print "  $AB_L"; done
            ui_print "防砖保护已启用: 新内核若无法启动将自动回退另一槽位"
        else
            ui_print "警告: 防砖保护写入失败 (misc 布局不支持?), 安装继续"
        fi
    else
        ui_print "警告: 无法确定当前槽位, 跳过防砖保护"
    fi
fi
