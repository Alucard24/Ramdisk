#!/sbin/busybox sh
# Alucard kernel script (Root helper)

BB=/sbin/busybox

mount -o remount,rw /system
$BB mount -t rootfs -o remount,rw rootfs

# some nice thing for dev
$BB ln -s /sys/devices/system/cpu/cpu0/cpufreq /cpufreq;
$BB ln -s /sys/devices/system/cpu/cpufreq/ /cpugov;

if [ ! -f /system/xbin/su ]; then
mv  /res/su /system/xbin/su
fi

chown 0.0 /system/xbin/su
chmod 06755 /system/xbin/su
symlink /system/xbin/su /system/bin/su

if [ ! -f /system/app/Superuser.apk ]; then
mv /res/Superuser.apk /system/app/Superuser.apk
fi

chown 0.0 /system/app/Superuser.apk
chmod 0644 /system/app/Superuser.apk

if [ ! -f /system/xbin/busybox ]; then
ln -s $BB /system/xbin/busybox
ln -s $BB /system/xbin/pkill
fi

if [ ! -f /system/bin/busybox ]; then
ln -s $BB /system/bin/busybox
ln -s $BB /system/bin/pkill
fi

if [ ! -f /system/app/STweaks.apk ]; then
  cat /res/STweaks.apk > /system/app/STweaks.apk
  chown 0.0 /system/app/STweaks.apk
  chmod 644 /system/app/STweaks.apk
fi

chmod 755 /res/customconfig/actions/controlswitch
chmod 755 /res/customconfig/actions/generic
chmod 755 /res/customconfig/actions/generic01
chmod 755 /res/customconfig/actions/generictag
chmod 755 /res/customconfig/actions/iosched
chmod 755 /res/customconfig/actions/cpugeneric
chmod 755 /res/customconfig/actions/cpuvolt
chmod 755 /res/customconfig/customconfig-helper
chmod 755 /res/customconfig/customconfig.xml.generate

rm /data/.alucard/customconfig.xml
rm /data/.alucard/action.cache

/system/bin/setprop pm.sleep_mode 1
/system/bin/setprop ro.ril.disable.power.collapse 0
/system/bin/setprop ro.telephony.call_ring.delay 1000

mkdir -p /mnt/ntfs
chmod 777 /mnt/ntfs
mount -o mode=0777,gid=1000 -t tmpfs tmpfs /mnt/ntfs

(
	# EFS Backup
	$BB sh /sbin/ext/efs-backup.sh;
)&

sync

if [ -d /system/etc/init.d ]; then
  $BB run-parts /system/etc/init.d
fi

chmod 755 /res/uci.sh
$BB sh /res/uci.sh apply

(
	# disabling knox security at boot
	$BB pm disable com.sec.knox.seandroid
)&

$BB mount -t rootfs -o remount,ro rootfs
mount -o remount,ro /system
