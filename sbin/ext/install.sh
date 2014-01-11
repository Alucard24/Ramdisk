#!/sbin/busybox sh

BB=/sbin/busybox

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;

$BB mount -o remount,rw /system;
$BB mount -o remount,rw /;

cd /;

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

if [ -f /system/app/Extweaks.apk ] || [ -f /data/app/com.darekxan.extweaks.ap*.apk ]; then
	$BB rm -f /system/app/Extweaks.apk > /dev/null 2>&1;
	$BB rm -f /data/app/com.darekxan.extweaks.ap*.apk > /dev/null 2>&1;
	$BB rm -rf /data/data/com.darekxan.extweaks.app > /dev/null 2>&1;
	$BB rm -f /data/dalvik-cache/*com.darekxan.extweaks.app* > /dev/null 2>&1;
fi;

STWEAKS_CHECK=$($BB find /data/app/ -name com.gokhanmoral.stweaks* | wc -l);

if [ "$STWEAKS_CHECK" -eq "1" ]; then
	$BB rm -f /data/app/com.gokhanmoral.stweaks* > /dev/null 2>&1;
	$BB rm -f /data/data/com.gokhanmoral.stweaks*/* > /dev/null 2>&1;
fi;

if [ -f /system/app/STweaks.apk ]; then
	stmd5sum=$($BB md5sum /system/app/STweaks.apk | $BB awk '{print $1}');
	stmd5sum_kernel=$(cat /res/stweaks_md5);
	if [ "$stmd5sum" != "$stmd5sum_kernel" ]; then
		$BB rm -f /system/app/STweaks.apk > /dev/null 2>&1;
		$BB rm -f /data/data/com.gokhanmoral.stweaks*/* > /dev/null 2>&1;
		$BB rm -f /data/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
		$BB rm -f /cache/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
		$BB cp /res/STweaks.apk /system/app/;
		$BB chown 0.0 /system/app/STweaks.apk;
		$BB chmod 644 /system/app/STweaks.apk;
	fi;
else
	$BB rm -f /data/app/com.gokhanmoral.*weak*.apk > /dev/null 2>&1;
	$BB rm -r /data/data/com.gokhanmoral.*weak*/* > /dev/null 2>&1;
	$BB rm -f /data/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
	$BB rm -f /cache/dalvik-cache/*gokhanmoral.*weak*.apk* > /dev/null 2>&1;
	$BB cp -a /res/STweaks.apk /system/app/;
	$BB chown 0.0 /system/app/STweaks.apk;
	$BB chmod 644 /system/app/STweaks.apk;
fi;

$BB mount -o remount,rw /;
$BB mount -o remount,rw /system;
