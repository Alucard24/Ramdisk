#!/sbin/busybox sh

BB=/sbin/busybox

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;

$BB mount -o remount,rw /system;
$BB mount -o remount,rw /;

(
	if [ ! -f /system/xbin/daemonsu ]; then
		$BB mv /res/daemonsu /system/xbin/daemonsu;
	fi;

	$BB mv /res/.has_su_daemon /system/etc/.has_su_daemon;
	$BB chmod 644 /system/etc/.has_su_daemon;

	$BB mv /res/install-recovery.sh /system/etc/install-recovery.sh;
	$BB chmod 755 /system/etc/install-recovery.sh;

	$BB chmod 6755 /system/xbin/su;
	$BB chmod 6755 /system/xbin/daemonsu;

	if [ ! -f /system/app/Superuser.apk ]; then
		$BB mv /res/Superuser.apk /system/app/Superuser.apk;
	fi;

	$BB chmod 644 /system/app/Superuser.apk;

	if [ ! -f /system/xbin/busybox ]; then
		$BB ln -s /sbin/busybox /system/xbin/busybox;
		$BB ln -s /sbin/busybox /system/xbin/pkill;
	fi;

	if [ ! -f /system/bin/busybox ]; then
		$BB ln -s /sbin/busybox /system/bin/busybox;
		$BB ln -s /sbin/busybox /system/bin/pkill;
	fi;

	if [ ! -f /system/app/STweaks.apk ]; then
		$BB cat /res/STweaks.apk > /system/app/STweaks.apk;
		$BB chmod 644 /system/app/STweaks.apk;
	fi;
)&

$BB mount -o remount,rw /;
$BB mount -o remount,rw /system;
