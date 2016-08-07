#!/sbin/bb/busybox sh

BB=/sbin/bb/busybox

if [ "$($BB mount | $BB grep rootfs | $BB cut -c 26-27 | $BB grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /;
fi;
if [ "$($BB mount | $BB grep system | $BB grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /system;
fi;

if [ -e /system/xbin/wget ]; then
	$BB rm /system/xbin/wget;
fi;
if [ -e /system/wget/wget ]; then
	$BB chmod 755 /system/wget/wget;
	$BB ln -s /system/wget/wget /system/xbin/wget;
fi;
if [ -e /system/xbin/su ]; then
	$BB chmod 06755 /system/xbin/su;
fi;
if [ -e /system/xbin/daemonsu ]; then
	$BB chmod 06755 /system/xbin/daemonsu;
fi;

$BB sh /sbin/ext/post-init.sh;

