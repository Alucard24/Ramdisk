#!/sbin/busybox sh

# stop ROM VM from booting!
# stop;

# set busybox location
BB=/sbin/busybox

$BB mount -o remount,rw,nosuid,nodev /cache;
$BB mount -o remount,rw,nosuid,nodev /data;
$BB mount -o remount,rw /;

# cleaning
$BB rm -rf /cache/lost+found/* 2> /dev/null;
$BB rm -rf /data/lost+found/* 2> /dev/null;
$BB rm -rf /data/tombstones/* 2> /dev/null;
$BB rm -rf /data/anr/* 2> /dev/null;

# critical Permissions fix
$BB chown -R root:root /sys/devices/system/cpu/;
$BB chown -R system:system /data/anr;
$BB chown -R root:root /data/property/;
$BB chmod -R 777 /tmp/;
$BB chmod -R 6755 /res;
$BB chmod -R 6755 /sbin/;
$BB chmod -R 6755 /sbin/ext/;
$BB chmod -R 0777 /dev/cpuctl/;
$BB chmod -R 0777 /data/system/inputmethod/;
$BB chmod -R 0777 /sys/devices/system/cpu/;
$BB chmod -R 0777 /data/anr/;
$BB chmod 0744 /proc/cmdline;
$BB chmod -R 0770 /data/property/;
$BB chmod -R 0771 /data/tombstones;

#BOOT_ROM()
#{
#	# Start ROM VM boot!
#	start;

	# start adb shell
#	start adbd;
#}
#BOOT_ROM;
