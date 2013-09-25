#!/sbin/busybox sh

BB=/sbin/busybox

$BB mount -o remount,rw /system;
$BB mount -t rootfs -o remount,rw rootfs;

$BB chmod -R 6755 /sbin;
$BB chmod -R 6755 /res;
$BB chmod -R 6777 /tmp;

PIDOFINIT=`pgrep -f "/sbin/ext/post-init.sh"`;
for i in $PIDOFINIT; do
	echo "-600" > /proc/${i}/oom_score_adj;
done;

if [ ! -d /data/.alucard ]; then
	$BB mkdir -p /data/.alucard;
fi;

# reset config-backup-restore
if [ -f /data/.alucard/restore_running ]; then
	rm -f /data/.alucard/restore_running;
fi;

#ccxmlsum=`md5sum /res/customconfig/customconfig.xml | awk '{print $1}'`
#if [ "a$ccxmlsum" != "a`cat /data/.alucard/.ccxmlsum`" ]; then
#	rm -f /data/.alucard/*.profile;
#	echo "$ccxmlsum" > /data/.alucard/.ccxmlsum;
#fi;

[ ! -f /data/.alucard/default.profile ] && cp -a /res/customconfig/default.profile /data/.alucard/default.profile;
[ ! -f /data/.alucard/battery.profile ] && cp -a /res/customconfig/battery.profile /data/.alucard/battery.profile;
[ ! -f /data/.alucard/performance.profile ] && cp -a /res/customconfig/performance.profile /data/.alucard/performance.profile;
[ ! -f /data/.alucard/extreme_performance.profile ] && cp -a /res/customconfig/extreme_performance.profile /data/.alucard/extreme_performance.profile;
[ ! -f /data/.alucard/extreme_battery.profile ] && cp -a /res/customconfig/extreme_battery.profile /data/.alucard/extreme_battery.profile;

$BB chmod -R 0777 /data/.alucard/;

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;

(
	if [ ! -f /system/xbin/su ]; then
		mv  /res/su /system/xbin/su;
	fi;

	if [ ! -f /system/xbin/daemonsu ]; then
		mv  /res/daemonsu /system/xbin/daemonsu;
	fi;

	mv  /res/.has_su_daemon /system/etc/.has_su_daemon;
	$BB chmod 644 /system/etc/.has_su_daemon;

	mv  /res/.installed_su_daemon /system/etc/.installed_su_daemon;
	$BB chmod 644 /system/etc/.installed_su_daemon;

	mv  /res/install-recovery.sh /system/etc/install-recovery.sh;
	$BB chmod 755 /system/etc/install-recovery.sh;

	$BB chmod 6755 /system/xbin/su;
	$BB chmod 6755 /system/xbin/daemonsu;
	symlink /system/xbin/su /system/bin/su;

	if [ ! -f /system/app/Superuser.apk ]; then
		mv /res/Superuser.apk /system/app/Superuser.apk;
	fi

	$BB chmod 644 /system/app/Superuser.apk;

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
		$BB chmod 644 /system/app/STweaks.apk;
	fi;

	# EFS Backup
	$BB sh /sbin/ext/efs-backup.sh;
)&

# busybox addons
if [ -e /system/xbin/busybox ]; then
	ln -s /system/xbin/busybox /sbin/ifconfig;
fi;

# some nice thing for dev
$BB ln -s /sys/devices/system/cpu/cpu0/cpufreq /cpufreq;
$BB ln -s /sys/devices/system/cpu/cpufreq/ /cpugov;

# Cortex parent should be ROOT/INIT and not STweaks
nohup /sbin/ext/cortexbrain-tune.sh;
CORTEX=`pgrep -f "/sbin/ext/cortexbrain-tune.sh"`;
echo "-900" > /proc/$CORTEX/oom_score_adj;

# create init.d folder if missing
if [ ! -d /system/etc/init.d ]; then
	mkdir -p /system/etc/init.d/
	$BB chmod 755 /system/etc/init.d/;
fi;

# disable debugging on some modules
if [ "$logger" == "off" ]; then
	echo "0" > /sys/module/kernel/parameters/initcall_debug;
	echo "0" > /sys/module/earlysuspend/parameters/debug_mask;
	echo "0" > /sys/module/alarm/parameters/debug_mask;
	echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
	echo "0" > /sys/module/binder/parameters/debug_mask;
	echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;
fi;

# for ntfs automounting
mount -t tmpfs -o mode=0777,gid=1000 tmpfs /mnt/ntfs

echo "0" > /tmp/uci_done;
chmod 666 /tmp/uci_done;

# disabling knox security at boot
/system/xbin/daemonsu --auto-daemon &
pm disable com.sec.knox.seandroid;

if [ -d /system/etc/init.d ]; then
	$BB run-parts /system/etc/init.d;
fi;

(

	# tweaks all the dm partitions that hold moved to sdcard apps
	sleep 30;
	#DM_COUNT=`ls -d /sys/block/dm* | wc -l`;
	#if [ "$DM_COUNT" -gt "0" ]; then
	#	for d in $($BB mount | grep dm | cut -d " " -f1 | grep -v vold); do
	#		$BB mount -o remount,ro,noauto_da_alloc $d;
	#	done;

	#	DM=`ls -d /sys/block/dm*`;
	#	for i in ${DM}; do
	#		echo "0" > ${i}/queue/rotational;
	#		echo "0" > ${i}/queue/iostats;
	#	done;
	#fi;

	# script finish here, so let me know when
        echo "Done Booting" > /data/dm-boot-check;
        date >> /data/dm-boot-check;
)&

(
	sleep 25;
	# stop uci.sh from running all the PUSH Buttons in stweaks on boot
	$BB mount -o remount,rw rootfs;
	$BB chown -R root:system /res/customconfig/actions/;
	$BB chmod -R 6755 /res/customconfig/actions/;
	$BB mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;
	$BB chmod 6755 /res/no-push-on-boot/*;

	# apply STweaks settings
	echo "booting" > /data/.alucard/booting;
	chmod 777 /data/.alucard/booting;
	pkill -f "com.gokhanmoral.stweaks.app";
	nohup $BB sh /res/uci.sh restore;
	UCI_PID=`pgrep -f "/res/uci.sh"`;
	echo "-800" > /proc/$UCI_PID/oom_score_adj;
	echo "1" > /tmp/uci_done;

	# restore all the PUSH Button Actions back to there location
	$BB mount -o remount,rw rootfs;
	$BB mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
	pkill -f "com.gokhanmoral.stweaks.app";

	# update cpu tunig after profiles load
	$BB sh /sbin/ext/cortexbrain-tune.sh apply_cpu update > /dev/null;
	$BB rm -f /data/.alucard/booting;

	# ###############################################################
	# I/O related tweaks
	# ###############################################################

	mount -o remount,rw /system;
	mount -o remount,rw /;
)&
