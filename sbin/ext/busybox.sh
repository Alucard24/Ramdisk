#!/sbin/bb/busybox sh

BB=/sbin/bb/busybox

if [ "$($BB mount | $BB grep rootfs | $BB cut -c 26-27 | $BB grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /;
fi;
if [ "$($BB mount | $BB grep system | $BB grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /system;
fi;

# update passwd and group files for busybox.
$BB echo "root:x:0:0::/:/sbin/bb/sh" > /system/etc/passwd;
$BB echo "system:x:1000:0::/:/sbin/bb/sh" >> /system/etc/passwd;
$BB echo "radio:x:1001:0::/:/sbin/bb/sh" >> /system/etc/passwd;
$BB echo "bluetooth:x:1002:0::/:/sbin/bb/sh" >> /system/etc/passwd;
$BB echo "wifi:x:1010:0::/:/sbin/bb/sh" >> /system/etc/passwd;
$BB echo "dhcp:x:1014:0::/:/sbin/bb/sh" >> /system/etc/passwd;
$BB echo "media:x:1013:0::/:/sbin/bb/sh" >> /system/etc/passwd;
$BB echo "gps:x:1021:0::/:/sbin/bb/sh" >> /system/etc/passwd;
$BB echo "nfc:x:1027:0::/:/sbin/bb/sh" >> /system/etc/passwd;
$BB chmod 755 /system/etc/passwd;
$BB chown 0:0 /system/etc/passwd;

$BB echo "root:x:0:root" > /system/etc/group;
$BB echo "system:x:1000:system" >> /system/etc/group;
$BB echo "radio:x:1001:radio" >> /system/etc/group;
$BB echo "bluetooth:x:1002:bluetooth" >> /system/etc/group;
$BB echo "wifi:x:1010:wifi" >> /system/etc/group;
$BB echo "dhcp:x:1014:dhcp" >> /system/etc/group;
$BB echo "media:x:1013:media" >> /system/etc/group;
$BB echo "gps:x:1021:gps" >> /system/etc/group;
$BB echo "nfc:x:1027:nfc" >> /system/etc/group;
$BB echo "sdcard_r:x:1028:sdcard_r" >> /system/etc/group;
$BB echo "cache:x:2001:cache" >> /system/etc/group;
$BB chmod 755 /system/etc/group;
$BB chown 0:0 /system/etc/group;

if [ -e /system/xbin/wget ]; then
	$BB rm /system/xbin/wget;
fi;
if [ -e /system/wget/wget ]; then
	$BB chmod 755 /system/wget/wget;
	$BB ln -s /system/wget/wget /system/xbin/wget;
fi;
if [ -e /su/bin/su ]; then
	$BB chmod 06755 /su/bin/su;
fi;
if [ -e /su/bin/daemonsu ]; then
	$BB chmod 06755 /su/bin/daemonsu;
fi;

$BB sh /sbin/ext/post-init.sh;

