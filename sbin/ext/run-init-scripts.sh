#!/sbin/busybox sh

BB=/sbin/busybox

if [ -d /system/etc/init.d ]; then
	chmod 755 /system/etc/init.d/*;
	$BB run-parts /system/etc/init.d/;
fi;
