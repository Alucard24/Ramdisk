#!/sbin/busybox sh
# Alucard kernel script (Root helper)

BB=/sbin/busybox

mount -o remount,rw /system;
$BB mount -o remount,rw /;

# some nice thing for dev
$BB ln -s /sys/devices/system/cpu/cpu0/cpufreq /cpufreq;
$BB ln -s /sys/devices/system/cpu/cpufreq/ /cpugov;

if [ ! -f /system/xbin/su ]; then
	mv  /res/su /system/xbin/su;
fi;

if [ ! -f /system/xbin/daemonsu ]; then
	mv  /res/daemonsu /system/xbin/daemonsu;
fi;

mv  /res/.has_su_daemon /system/etc/.has_su_daemon;
$BB chmod 0644 /system/etc/.has_su_daemon;

mv  /res/.installed_su_daemon /system/etc/.installed_su_daemon;
$BB chmod 0644 /system/etc/.installed_su_daemon;

mv  /res/install-recovery.sh /system/etc/install-recovery.sh;
$BB chmod 0755 /system/etc/install-recovery.sh;

$BB chmod -R 6755 /sbin;
chown 0.0 /system/xbin/su;
$BB chmod 6755 /system/xbin/su;
chown 0.0 /system/xbin/daemonsu;
$BB chmod 6755 /system/xbin/daemonsu;
symlink /system/xbin/su /system/bin/su;

if [ ! -f /system/app/Superuser.apk ]; then
	mv /res/Superuser.apk /system/app/Superuser.apk;
fi

chown 0.0 /system/app/Superuser.apk;
$BB chmod 0644 /system/app/Superuser.apk;

if [ ! -f /system/xbin/busybox ]; then
	ln -s /sbin/busybox /system/xbin/busybox;
	ln -s /sbin/busybox /system/xbin/pkill;
fi

if [ ! -f /system/bin/busybox ]; then
	ln -s /sbin/busybox /system/bin/busybox;
	ln -s /sbin/busybox /system/bin/pkill;
fi;

if [ ! -f /system/app/STweaks.apk ]; then
	cat /res/STweaks.apk > /system/app/STweaks.apk;
	chown 0.0 /system/app/STweaks.apk;
	$BB chmod 644 /system/app/STweaks.apk;
fi;

$BB chmod 755 /res/customconfig/actions/controlswitch;
$BB chmod 755 /res/customconfig/actions/generic;
$BB chmod 755 /res/customconfig/actions/generic01;
$BB chmod 755 /res/customconfig/actions/generictag;
$BB chmod 755 /res/customconfig/actions/iosched;
$BB chmod 755 /res/customconfig/actions/cpugeneric;
$BB chmod 755 /res/customconfig/actions/cpuvolt;
$BB chmod 755 /res/customconfig/customconfig-helper;
$BB chmod 755 /res/customconfig/customconfig.xml.generate;

rm /data/.alucard/customconfig.xml;
rm /data/.alucard/action.cache;
$BB chmod -R 6777 /data/.alucard;

/system/bin/setprop pm.sleep_mode 1;
/system/bin/setprop ro.ril.disable.power.collapse 0;
/system/bin/setprop ro.telephony.call_ring.delay 1000;

mkdir -p /mnt/ntfs;
$BB chmod 777 /mnt/ntfs;
mount -o mode=0777,gid=1000 -t tmpfs tmpfs /mnt/ntfs;

(
	# EFS Backup
	$BB sh /sbin/ext/efs-backup.sh;
)&

sync;

# disabling knox security at boot
/system/xbin/daemonsu --auto-daemon &
pm disable com.sec.knox.seandroid;

if [ -d /system/etc/init.d ]; then
	$BB run-parts /system/etc/init.d;
fi;

(
	sleep 20;
	$BB mount -o remount,rw /;
	$BB chown -R root:system /res/customconfig/actions/;
	$BB chmod -R 6755 /res/customconfig/actions/;
	$BB chmod 6755 /res/uci.sh;
	$BB sh /res/uci.sh apply;
	mount -o remount,ro /system;
	mount -o remount,ro /;
	#mount -o remount,rw /system;
	#mount -o remount,rw /;
)&

