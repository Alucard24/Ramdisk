#!/sbin/busybox sh

BB=/sbin/busybox

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;

$BB mount -o remount,rw /system;
$BB mount -o remount,rw /;

cd /;

fi;

STWEAKS_CHECK=$($BB find /data/app/ -name com.gokhanmoral.stweaks* | wc -l);

if [ "$STWEAKS_CHECK" -eq "1" ]; then
	$BB rm -f /data/app/com.gokhanmoral.stweaks* > /dev/null 2>&1;
	$BB rm -f /data/data/com.gokhanmoral.stweaks*/* > /dev/null 2>&1;
fi;

if [ -f /system/app/STweaks.apk ]; then
	stmd5sum=$($BB md5sum /system/app/STweaks.apk | $BB awk '{print $1}');
	stmd5sum_kernel=$($BB cat /res/stweaks_md5);
	if [ "$stmd5sum" != "$stmd5sum_kernel" ]; then
		$BB rm -f /system/app/STweaks.apk > /dev/null 2>&1;
		$BB rm -f /data/data/com.gokhanmoral.stweaks*/* > /dev/null 2>&1;
		$BB cp /res/misc/payload/STweaks.apk /system/app/;
		$BB chown root.root /system/app/STweaks.apk;
		$BB chmod 644 /system/app/STweaks.apk;
	fi;
else
	$BB rm -f /data/app/com.gokhanmoral.*weak*.apk > /dev/null 2>&1;
	$BB rm -r /data/data/com.gokhanmoral.*weak*/* > /dev/null 2>&1;
	$BB cp -a /res/misc/payload/STweaks.apk /system/app/;
	$BB chown root.root /system/app/STweaks.apk;
	$BB chmod 644 /system/app/STweaks.apk;
fi;

$BB mount -o remount,rw /;
$BB mount -o remount,rw /system;
