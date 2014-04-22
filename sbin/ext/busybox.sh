#!/sbin/busybox sh

BB=/sbin/busybox

$BB mount -o remount,rw /system;
$BB mount -o remount,rw /;

# installe latest busybox to ROM
$BB cp /sbin/busybox /system/xbin/;
/system/xbin/busybox --install -s /system/xbin/
chmod 06755 /system/xbin/busybox;

$BB sh /sbin/ext/post-init.sh;

