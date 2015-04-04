#!/sbin/busybox sh

# Kernel Tuning by Alucard. Thanks to Dorimanx.

BB=/sbin/busybox

# protect init from oom
echo "-1000" > /proc/1/oom_score_adj;

PIDOFINIT=$(pgrep -f "/sbin/ext/post-init.sh");
for i in $PIDOFINIT; do
	echo "-600" > /proc/"$i"/oom_score_adj;
done;

OPEN_RW()
{
	ROOTFS_MOUNT=$(mount | grep rootfs | cut -c26-27 | grep -c rw)
	SYSTEM_MOUNT=$(mount | grep system | cut -c69-70 | grep -c rw)
	if [ "$ROOTFS_MOUNT" -eq "0" ]; then
		$BB mount -o remount,rw /;
	fi;
	if [ "$SYSTEM_MOUNT" -eq "0" ]; then
		$BB mount -o remount,rw /system;
	fi;
}
OPEN_RW;

# run ROM scripts
$BB sh /init.qcom.post_boot.sh;

# fix storage folder owner
# $BB chown system.sdcard_rw /storage;

# Boot with ROW I/O Gov
$BB echo "row" > /sys/block/mmcblk0/queue/scheduler;

# clean old modules from /system and add new from ramdisk

# create init.d folder if missing
if [ ! -d /system/etc/init.d ]; then
	mkdir -p /system/etc/init.d/
	$BB chmod 755 /system/etc/init.d/;
fi;

OPEN_RW;

# some nice thing for dev
if [ ! -e /cpufreq ]; then
	$BB ln -s /sys/devices/system/cpu/cpu0/cpufreq/ /cpufreq;
	$BB ln -s /sys/devices/system/cpu/cpufreq/ /cpugov;
	$BB ln -s /sys/module/msm_thermal/parameters/ /cputemp;
	$BB ln -s /sys/kernel/alucard_hotplug/ /hotplugs/alucard;
	$BB ln -s /sys/kernel/intelli_plug/ /hotplugs/intelli;
	$BB ln -s /sys/module/msm_hotplug/ /hotplugs/msm_hotplug;
	$BB ln -s /sys/devices/system/cpu/cpufreq/all_cpus/ /all_cpus;
fi;

# cleaning
$BB rm -rf /cache/lost+found/* 2> /dev/null;
$BB rm -rf /data/lost+found/* 2> /dev/null;
$BB rm -rf /data/tombstones/* 2> /dev/null;

OPEN_RW;

CRITICAL_PERM_FIX()
{
	# critical Permissions fix
	$BB chown -R system:system /data/anr;
	$BB chown -R root:root /tmp;
	$BB chown -R root:root /res;
	$BB chown -R root:root /sbin;
	$BB chown -R root:root /lib;
	$BB chmod -R 777 /tmp/;
	$BB chmod -R 775 /res/;
	$BB chmod -R 06755 /sbin/ext/;
	$BB chmod -R 0777 /data/anr/;
	$BB chmod -R 0400 /data/tombstones;
	$BB chmod 06755 /sbin/busybox
}
CRITICAL_PERM_FIX;

# oom and mem perm fix
$BB chmod 666 /sys/module/lowmemorykiller/parameters/cost;
$BB chmod 666 /sys/module/lowmemorykiller/parameters/adj;
$BB chmod 666 /sys/module/lowmemorykiller/parameters/minfree

# make sure we own the device nodes
# $BB chown system /sys/devices/system/cpu/cpufreq/alucard/*
$BB chown system /sys/devices/system/cpu/cpu0/cpufreq/*
$BB chown system /sys/devices/system/cpu/cpu1/online
$BB chown system /sys/devices/system/cpu/cpu2/online
$BB chown system /sys/devices/system/cpu/cpu3/online
$BB chmod 666 /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
$BB chmod 666 /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
$BB chmod 666 /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
$BB chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq
$BB chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/stats/*
$BB chmod 666 /sys/devices/system/cpu/cpufreq/all_cpus/*
$BB chmod 666 /sys/devices/system/cpu/cpu1/online
$BB chmod 666 /sys/devices/system/cpu/cpu2/online
$BB chmod 666 /sys/devices/system/cpu/cpu3/online
$BB chmod 666 /sys/module/msm_thermal/parameters/*
$BB chmod 666 /sys/kernel/intelli_plug/*
$BB chmod 666 /sys/class/kgsl/kgsl-3d0/max_gpuclk
$BB chmod 666 /sys/devices/platform/kgsl-3d0/kgsl/kgsl-3d0/pwrscale/trustzone/governor

# make sure our max gpu clock is set via sysfs
echo 450000000 > /sys/class/kgsl/kgsl-3d0/max_gpuclk

# Fix ROM dev wrong sets.
setprop persist.adb.notify 0
setprop pm.sleep_mode 1
setprop persist.service.btui.use_aptx 1

if [ ! -d /data/.alucard ]; then
	$BB mkdir -p /data/.alucard;
fi;

# reset profiles auto trigger to be used by kernel ADMIN, in case of need, if new value added in default profiles
# just set numer $RESET_MAGIC + 1 and profiles will be reset one time on next boot with new kernel.
# incase that ADMIN feel that something wrong with global STweaks config and profiles, then ADMIN can add +1 to CLEAN_ALU_DIR
# to clean all files on first boot from /data/.alucard/ folder.
RESET_MAGIC=10;
CLEAN_ALU_DIR=4;

if [ ! -e /data/.alucard/reset_profiles ]; then
	echo "$RESET_MAGIC" > /data/.alucard/reset_profiles;
fi;
if [ ! -e /data/reset_alu_dir ]; then
	echo "$CLEAN_ALU_DIR" > /data/reset_alu_dir;
fi;
if [ -e /data/.alucard/.active.profile ]; then
	PROFILE=$(cat /data/.alucard/.active.profile);
else
	echo "default" > /data/.alucard/.active.profile;
	PROFILE=$(cat /data/.alucard/.active.profile);
fi;
if [ "$(cat /data/reset_alu_dir)" -eq "$CLEAN_ALU_DIR" ]; then
	if [ "$(cat /data/.alucard/reset_profiles)" != "$RESET_MAGIC" ]; then
		if [ ! -e /data/.alucard_old ]; then
			mkdir /data/.alucard_old;
		fi;
		cp -a /data/.alucard/*.profile /data/.alucard_old/;
		$BB rm -f /data/.alucard/*.profile;
		if [ -e /data/data/com.af.synapse/databases ]; then
			$BB rm -R /data/data/com.af.synapse/databases;
		fi;
		echo "$RESET_MAGIC" > /data/.alucard/reset_profiles;
	else
		echo "no need to reset profiles or delete .alucard folder";
	fi;
else
	# Clean /data/.alucard/ folder from all files to fix any mess but do it in smart way.
	if [ -e /data/.alucard/"$PROFILE".profile ]; then
		cp /data/.alucard/"$PROFILE".profile /sdcard/"$PROFILE".profile_backup;
	fi;
	if [ ! -e /data/.alucard_old ]; then
		mkdir /data/.alucard_old;
	fi;
	cp -a /data/.alucard/* /data/.alucard_old/;
	$BB rm -f /data/.alucard/*
	if [ -e /data/data/com.af.synapse/databases ]; then
		$BB rm -R /data/data/com.af.synapse/databases;
	fi;
	echo "$CLEAN_ALU_DIR" > /data/reset_alu_dir;
	echo "$RESET_MAGIC" > /data/.alucard/reset_profiles;
	echo "$PROFILE" > /data/.alucard/.active.profile;
fi;

[ ! -f /data/.alucard/default.profile ] && cp -a /res/customconfig/default.profile /data/.alucard/default.profile;
[ ! -f /data/.alucard/battery.profile ] && cp -a /res/customconfig/battery.profile /data/.alucard/battery.profile;
[ ! -f /data/.alucard/performance.profile ] && cp -a /res/customconfig/performance.profile /data/.alucard/performance.profile;
[ ! -f /data/.alucard/extreme_performance.profile ] && cp -a /res/customconfig/extreme_performance.profile /data/.alucard/extreme_performance.profile;
[ ! -f /data/.alucard/extreme_battery.profile ] && cp -a /res/customconfig/extreme_battery.profile /data/.alucard/extreme_battery.profile;

$BB chmod -R 0777 /data/.alucard/;

. /res/customconfig/customconfig-helper;
read_defaults;
read_config;

# start CORTEX by tree root, so it's will not be terminated.
sed -i "s/cortexbrain_background_process=[0-1]*/cortexbrain_background_process=1/g" /sbin/ext/cortexbrain-tune.sh;
if [ "$(pgrep -f "cortexbrain-tune.sh" | wc -l)" -eq "0" ]; then
	$BB nohup $BB sh /sbin/ext/cortexbrain-tune.sh > /data/.alucard/cortex.txt &
fi;

#	# Apps Install
OPEN_RW;
# $BB sh /sbin/ext/install.sh;

if [ "$stweaks_boot_control" == "yes" ]; then
	# apply Synapse monitor
	$BB sh /res/synapse/uci reset;
	# apply STweaks settings
	$BB sh /res/uci_boot.sh apply;
	$BB mv /res/uci_boot.sh /res/uci.sh;
else
	$BB mv /res/uci_boot.sh /res/uci.sh;
fi;

######################################
# Loading Modules
######################################
MODULES_LOAD()
{
	# order of modules load is important

	if [ "$cifs_module" == "on" ]; then
		if [ -e /system/lib/modules/cifs.ko ]; then
			$BB insmod /system/lib/modules/cifs.ko;
		else
			$BB insmod /lib/modules/cifs.ko;
		fi;
	else
		echo "no user modules loaded";
	fi;
}

# enable kmem interface for everyone by GM
echo "0" > /proc/sys/kernel/kptr_restrict;

# disable debugging on some modules
if [ "$android_logger" -ge "1" ]; then
	echo "N" > /sys/module/kernel/parameters/initcall_debug;
#	echo "0" > /sys/module/alarm/parameters/debug_mask;
#	echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
#	echo "0" > /sys/module/binder/parameters/debug_mask;
	echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;
#	echo "0" > /sys/kernel/debug/clk/debug_suspend;
#	echo "0" > /sys/kernel/debug/msm_vidc/debug_level;
#	echo "0" > /sys/module/ipc_router/parameters/debug_mask;
#	echo "0" > /sys/module/msm_serial_hs/parameters/debug_mask;
#	echo "0" > /sys/module/msm_show_resume_irq/parameters/debug_mask;
#	echo "0" > /sys/module/pm_8x60/parameters/debug_mask;
fi;

OPEN_RW;

# for ntfs automounting
if [ ! -d /mnt/ntfs ]; then
	$BB mkdir /mnt/ntfs
	$BB mount -t tmpfs -o mode=0777,gid=1000 tmpfs /mnt/ntfs
fi;


# Turn off CORE CONTROL, to boot on all cores!
$BB chmod 666 /sys/module/msm_thermal/core_control/*
echo "0" > /sys/module/msm_thermal/core_control/core_control;

# Start any init.d scripts that may be present in the rom or added by the user
$BB chmod 755 /system/etc/init.d/*;
if [ "$init_d" == "on" ]; then
	(
		$BB nohup $BB run-parts /system/etc/init.d/ > /data/.alucard/init.d.txt &
	)&
else
	if [ -e /system/etc/init.d/99SuperSUDaemon ]; then
		$BB nohup $BB sh /system/etc/init.d/99SuperSUDaemon > /data/.alucard/root.txt &
	else
		echo "no root script in init.d";
	fi;
fi;

# Fix critical perms again after init.d mess
CRITICAL_PERM_FIX;

# Temporary GooglePlayService fix.
if [ "$gpservicefix" == "yes" ]; then
	pm enable com.google.android.gms/.update.SystemUpdateActivity
	pm enable com.google.android.gms/.update.SystemUpdateService
	pm enable com.google.android.gms/.update.SystemUpdateService$ActiveReceiver
	pm enable com.google.android.gms/.update.SystemUpdateService$Receiver
	pm enable com.google.android.gms/.update.SystemUpdateService$SecretCodeReceiver
	pm enable com.google.android.gsf/.update.SystemUpdateActivity
	pm enable com.google.android.gsf/.update.SystemUpdatePanoActivity
	pm enable com.google.android.gsf/.update.SystemUpdateService
	pm enable com.google.android.gsf/.update.SystemUpdateService$Receiver
	pm enable com.google.android.gsf/.update.SystemUpdateService$SecretCodeReceiver
fi;

if [ "$stweaks_boot_control" == "yes" ]; then
	$BB sh /sbin/ext/cortexbrain-tune.sh apply_cpu update > /dev/null;
	# Load Custom Modules
	MODULES_LOAD;
fi;

echo "0" > /cputemp/freq_limit_debug;

sleep 35;

# script finish here, so let me know when
TIME_NOW=$(date)
echo "$TIME_NOW" > /data/boot_log_dm

$BB mount -o remount,ro /system;

