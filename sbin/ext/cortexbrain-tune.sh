#!/sbin/busybox sh

#Credits:
# Zacharias.maladroit
# Voku1987
# Collin_ph@xda
# Dorimanx@xda
# Gokhanmoral@xda
# Johnbeetee
# Alucard_24@xda

# TAKE NOTE THAT LINES PRECEDED BY A "#" IS COMMENTED OUT.
#
# This script must be activated after init start =< 25sec or parameters from /sys/* will not be loaded.

# change mode for /tmp/
chmod -R 777 /tmp/;

# ==============================================================
# GLOBAL VARIABLES || without "local" also a variable in a function is global
# ==============================================================

FILE_NAME=$0;
PIDOFCORTEX=$$;
# (since we don't have the recovery source code I can't change the ".alucard" dir, so just leave it there for history)
DATA_DIR=/data/.alucard;
WAS_IN_SLEEP_MODE=1;
NOW_CALL_STATE=0;
USB_POWER=0;
TELE_DATA=init;
# read sd-card size, set via boot
EXTERNAL_SDCARD_CM=`mount | grep "/storage/sdcard1" | wc -l`;
EXTERNAL_SDCARD_STOCK=`mount | grep "/storage/extSdCard" | wc -l`;

# ==============================================================
# INITIATE
# ==============================================================

# get values from profile
PROFILE=`cat $DATA_DIR/.active.profile`;
. $DATA_DIR/${PROFILE}.profile;

# check if dumpsys exist in ROM
if [ -e /system/bin/dumpsys ]; then
	DUMPSYS_STATE=1;
else
	DUMPSYS_STATE=0;
fi;

# set initial vm.dirty vales
echo "600" > /proc/sys/vm/dirty_writeback_centisecs;
echo "3000" > /proc/sys/vm/dirty_expire_centisecs;

# ==============================================================
# FILES FOR VARIABLES || we need this for write variables from child-processes to parent
# ==============================================================

# WIFI HELPER
WIFI_HELPER_AWAKE="$DATA_DIR/WIFI_HELPER_AWAKE";
WIFI_HELPER_TMP="$DATA_DIR/WIFI_HELPER_TMP";
echo "1" > $WIFI_HELPER_TMP;

# MOBILE HELPER
MOBILE_HELPER_AWAKE="$DATA_DIR/MOBILE_HELPER_AWAKE";
MOBILE_HELPER_TMP="$DATA_DIR/MOBILE_HELPER_TMP";
echo "1" > $MOBILE_HELPER_TMP;

# ==============================================================
# I/O-TWEAKS
# ==============================================================
IO_TWEAKS()
{
	if [ "$cortexbrain_io" == "on" ]; then

		local i="";

		#local ZRM=`ls -d /sys/block/zram*`;
		#for i in $ZRM; do
		#	if [ -e $i/queue/rotational ]; then
		#		echo "0" > $i/queue/rotational;
		#	fi;

		#	if [ -e $i/queue/iostats ]; then
		#		echo "0" > $i/queue/iostats;
		#	fi;

		#	if [ -e $i/queue/rq_affinity ]; then
		#		echo "1" > $i/queue/rq_affinity;
		#	fi;
		#done;

		local SD=`ls -d /sys/block/mmcblk0*`;
		for i in $SD; do
			if [ -e $i/queue/scheduler ]; then
				echo $internal_iosched > $i/queue/scheduler;
			fi;

		done;

		local MMC=`ls -d /sys/block/mmcblk1*`;
		for i in $MMC; do
			if [ -e $i/queue/scheduler ]; then
				echo $sd_iosched > $i/queue/scheduler;
			fi;

			if [ -e $i/queue/rotational ]; then
				echo "0" > $i/queue/rotational;
			fi;

			if [ -e $i/queue/iostats ]; then
				echo "0" > $i/queue/iostats;
			fi;

			if [ -e $i/queue/nr_requests ]; then
				echo "64" > $i/queue/nr_requests; # default: 128
			fi;
		done;

		# our storage is 16GB, best is 1024KB readahead
		# see https://github.com/Keff/samsung-kernel-msm7x30/commit/a53f8445ff8d947bd11a214ab42340cc6d998600#L1R627
		echo "1024" > /sys/block/mmcblk0/queue/read_ahead_kb;

		if [ -e /sys/block/mmcblk1/queue/read_ahead_kb ]; then
			echo "$cortexbrain_read_ahead_kb" > /sys/block/mmcblk1/queue/read_ahead_kb;
		fi;

		echo "45" > /proc/sys/fs/lease-break-time;

		log -p i -t $FILE_NAME "*** IO_TWEAKS ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
apply_cpu="$2";
if [ "$apply_cpu" != "update" ]; then
	IO_TWEAKS;
fi;

# ==============================================================
# BATTERY-TWEAKS
# ==============================================================
BATTERY_TWEAKS()
{
	if [ "$cortexbrain_battery" == "on" ]; then
		# battery-calibration if battery is full
		local LEVEL=`cat /sys/class/power_supply/battery/capacity`;
		local CURR_ADC=`cat /sys/class/power_supply/battery/chg_current_adc`;
		local BATTFULL=`cat /sys/class/power_supply/battery/status`;
		local i="";
		local bus="";

		log -p i -t $FILE_NAME "*** BATTERY - LEVEL: $LEVEL - CUR: $CURR_ADC ***";

		# if [ "$LEVEL" -eq "100" ] && [ "$BATTFULL" -eq "Full" ]; then
		#	rm -f /data/system/batterystats.bin;
		#	log -p i -t $FILE_NAME "battery-calibration done ...";
		# fi;

		# USB: power support
		local POWER_LEVEL=`ls /sys/bus/usb/devices/*/power/control`;
		for i in $POWER_LEVEL; do
			chmod 777 $i;
			echo "auto" > $i;
		done;

		local POWER_AUTOSUSPEND=`ls /sys/bus/usb/devices/*/power/autosuspend`;
		for i in $POWER_AUTOSUSPEND; do
			chmod 777 $i;
			echo "1" > $i;
		done;

		# BUS: power support
		local buslist="spi i2c sdio";
		for bus in $buslist; do
			local POWER_CONTROL=`ls /sys/bus/$bus/devices/*/power/control`;
			for i in $POWER_CONTROL; do
				chmod 777 $i;
				echo "auto" > $i;
			done;
		done;

		log -p i -t $FILE_NAME "*** BATTERY_TWEAKS ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
# run this tweak once, if the background-process is disabled
apply_cpu="$2";
if [ "$apply_cpu" != "update" ] || [ "$cortexbrain_background_process" -eq "0" ]; then
	BATTERY_TWEAKS;
fi;

# ==============================================================
# AUTO MOUNTING ROOTFS AS RW
# ==============================================================

AUTOMOUNT_ROOTFS()
{
	sleep 1;
	mount -o remount,rw /;
}
# this needed for mounting root as rw
automount_rootfs="$2";
if [ "$automount_rootfs" == "rw" ] || [ "$cortexbrain_background_process" -eq "0" ]; then
	AUTOMOUNT_ROOTFS;
fi;

# ==============================================================
# CPU-TWEAKS
# ==============================================================

CPU_HOTPLUG_TWEAKS()
{
	local state="$1";

	# MSM MPDecision
	local msm_mpdecision_tmp="mpdecision";
	local msm_value_tmp=`pgrep -f "/system/bin/mpdecision" | wc -l`;

	# Intelli plug
	local intelli_plug_active_tmp="/sys/kernel/intelli_plug/intelli_plug_active";
	if [ ! -e $intelli_plug_active_tmp ]; then
		intelli_plug_active_tmp="/dev/null";
	fi;
	local intelli_value_tmp=`cat /sys/kernel/intelli_plug/intelli_plug_active`;

	# Alucard hotplug
	local hotplug_enable_tmp="/sys/kernel/alucard_hotplug/hotplug_enable";
	if [ ! -e $hotplug_enable_tmp ]; then
			hotplug_enable_tmp="/dev/null";
	fi;
	local alucard_value_tmp=`cat /sys/kernel/alucard_hotplug/hotplug_enable`;

	local hotplug_sampling_rate_tmp="/sys/kernel/alucard_hotplug/hotplug_sampling_rate";
	if [ ! -e $hotplug_sampling_rate_tmp ]; then
		hotplug_sampling_rate_tmp="/dev/null";
	fi;

	local cpu_up_rate_tmp="/sys/kernel/alucard_hotplug/cpu_up_rate";
	if [ ! -e $cpu_up_rate_tmp ]; then
		cpu_up_rate_tmp="/dev/null";
	fi;

	local cpu_down_rate_tmp="/sys/kernel/alucard_hotplug/cpu_down_rate";
	if [ ! -e $cpu_down_rate_tmp ]; then
		cpu_down_rate_tmp="/dev/null";
	fi;

	local hotplug_freq_1_1_tmp="/sys/kernel/alucard_hotplug/hotplug_freq_1_1";
	if [ ! -e $hotplug_freq_1_1_tmp ]; then
		hotplug_freq_1_1_tmp="/dev/null";
	fi;

	local hotplug_freq_2_0_tmp="/sys/kernel/alucard_hotplug/hotplug_freq_2_0";
	if [ ! -e $hotplug_freq_2_0_tmp ]; then
		hotplug_freq_2_0_tmp="/dev/null";
	fi;

	local hotplug_freq_2_1_tmp="/sys/kernel/alucard_hotplug/hotplug_freq_2_1";
	if [ ! -e $hotplug_freq_2_1_tmp ]; then
		hotplug_freq_2_1_tmp="/dev/null";
	fi;

	local hotplug_freq_3_0_tmp="/sys/kernel/alucard_hotplug/hotplug_freq_3_0";
	if [ ! -e $hotplug_freq_3_0_tmp ]; then
		hotplug_freq_3_0_tmp="/dev/null";
	fi;

	local hotplug_freq_3_1_tmp="/sys/kernel/alucard_hotplug/hotplug_freq_3_1";
	if [ ! -e $hotplug_freq_3_1_tmp ]; then
		hotplug_freq_3_1_tmp="/dev/null";
	fi;

	local hotplug_freq_4_0_tmp="/sys/kernel/alucard_hotplug/hotplug_freq_4_0";
	if [ ! -e $hotplug_freq_4_0_tmp ]; then
		hotplug_freq_4_0_tmp="/dev/null";
	fi;

	local hotplug_load_1_1_tmp="/sys/kernel/alucard_hotplug/hotplug_load_1_1";
	if [ ! -e $hotplug_load_1_1_tmp ]; then
		hotplug_load_1_1_tmp="/dev/null";
	fi;

	local hotplug_load_2_0_tmp="/sys/kernel/alucard_hotplug/hotplug_load_2_0";
	if [ ! -e $hotplug_load_2_0_tmp ]; then
		hotplug_load_2_0_tmp="/dev/null";
	fi;

	local hotplug_load_2_1_tmp="/sys/kernel/alucard_hotplug/hotplug_load_2_1";
	if [ ! -e $hotplug_load_2_1_tmp ]; then
		hotplug_load_2_1_tmp="/dev/null";
	fi;

	local hotplug_load_3_0_tmp="/sys/kernel/alucard_hotplug/hotplug_load_3_0";
	if [ ! -e $hotplug_load_3_0_tmp ]; then
		hotplug_load_3_0_tmp="/dev/null";
	fi;

	local hotplug_load_3_1_tmp="/sys/kernel/alucard_hotplug/hotplug_load_3_1";
	if [ ! -e $hotplug_load_3_1_tmp ]; then
		hotplug_load_3_1_tmp="/dev/null";
	fi;

	local hotplug_load_4_0_tmp="/sys/kernel/alucard_hotplug/hotplug_load_4_0";
	if [ ! -e $hotplug_load_4_0_tmp ]; then
		hotplug_load_4_0_tmp="/dev/null";
	fi;

	local hotplug_rq_1_1_tmp="/sys/kernel/alucard_hotplug/hotplug_rq_1_1";
	if [ ! -e $hotplug_rq_1_1_tmp ]; then
		hotplug_rq_1_1_tmp="/dev/null";
	fi;

	local hotplug_rq_2_0_tmp="/sys/kernel/alucard_hotplug/hotplug_rq_2_0";
	if [ ! -e $hotplug_rq_2_0_tmp ]; then
		hotplug_rq_2_0_tmp="/dev/null";
	fi;

	local hotplug_rq_2_1_tmp="/sys/kernel/alucard_hotplug/hotplug_rq_2_1";
	if [ ! -e $hotplug_rq_2_1_tmp ]; then
		hotplug_rq_2_1_tmp="/dev/null";
	fi;

	local hotplug_rq_3_0_tmp="/sys/kernel/alucard_hotplug/hotplug_rq_3_0";
	if [ ! -e $hotplug_rq_3_0_tmp ]; then
		hotplug_rq_3_0_tmp="/dev/null";
	fi;

	local hotplug_rq_3_1_tmp="/sys/kernel/alucard_hotplug/hotplug_rq_3_1";
	if [ ! -e $hotplug_rq_3_1_tmp ]; then
		hotplug_rq_3_1_tmp="/dev/null";
	fi;

	local hotplug_rq_4_0_tmp="/sys/kernel/alucard_hotplug/hotplug_rq_4_0";
	if [ ! -e $hotplug_rq_4_0_tmp ]; then
		hotplug_rq_4_0_tmp="/dev/null";
	fi;

	local maxcoreslimit_tmp="/sys/kernel/alucard_hotplug/maxcoreslimit";
	if [ ! -e $maxcoreslimit_tmp ]; then
		maxcoreslimit_tmp="/dev/null";
	fi;

	local eco_mode_active_tmp="/sys/kernel/intelli_plug/eco_mode_active";
	if [ ! -e $eco_mode_active_tmp ]; then
		eco_mode_active_tmp="/dev/null";
	fi;

	local strict_mode_active_tmp="/sys/kernel/intelli_plug/strict_mode_active";
	if [ ! -e $strict_mode_active_tmp ]; then
		strict_mode_active_tmp="/dev/null";
	fi;

	if [ "$cpuhotplugging" -eq "1" ]; then

		#disable intelli_plug
		if [ "$intelli_value_tmp" -eq "1" ]; then
			echo "0" > $intelli_plug_active_tmp;
		fi;

		#disable alucard_hotplug
		if [ "$alucard_value_tmp" -eq "1" ]; then
			echo "0" > $hotplug_enable_tmp;
		fi;

		#enable MSM MPDecision
		if [ "$msm_value_tmp" -eq "0" ]; then
			start $msm_mpdecision_tmp --no_sleep --avg_comp;
		fi;

		log -p i -t $FILE_NAME "*** MSM_MPDECISION ***: enabled";
	elif [ "$cpuhotplugging" -eq "2" ]; then
		#disable MSM MPDecision
		if [ "$msm_value_tmp" -eq "1" ]; then
			stop $msm_mpdecision_tmp;
		fi;

		#disable alucard_hotplug
		if [ "$alucard_value_tmp" -eq "1" ]; then
			echo "0" > $hotplug_enable_tmp;
		fi;

		#enable intelli_plug
		if [ "$intelli_value_tmp" -eq "0" ]; then
			echo "1" > $intelli_plug_active_tmp;
		fi;

		# sleep-settings
		if [ "$state" == "sleep" ]; then
			echo "$eco_mode_active_sleep" > $eco_mode_active_tmp;
			echo "$strict_mode_active_sleep" > $strict_mode_active_tmp;
		# awake-settings
		elif [ "$state" == "awake" ]; then
			echo "$eco_mode_active" > $eco_mode_active_tmp;
			echo "$strict_mode_active" > $strict_mode_active_tmp;
		fi;

	#	log -p i -t $FILE_NAME "*** INTELLI_PLUG ***: enabled";
	elif [ "$cpuhotplugging" -eq "3" ]; then
		#disable MSM MPDecision
		if [ "$msm_value_tmp" -eq "1" ]; then
			stop $msm_mpdecision_tmp;
		fi;

		#disable intelli_plug
		if [ "$intelli_value_tmp" -eq "1" ]; then
			echo "0" > $intelli_plug_active_tmp;
		fi;

		#enable alucard_hotplug
		if [ "$alucard_value_tmp" -eq "0" ]; then
			echo "1" > $hotplug_enable_tmp;
		fi

		# sleep-settings
		if [ "$state" == "sleep" ]; then
			echo "$hotplug_sampling_rate_sleep" > $hotplug_sampling_rate_tmp;
			echo "$cpu_up_rate_sleep" > $cpu_up_rate_tmp;
			echo "$cpu_down_rate_sleep" > $cpu_down_rate_tmp;
			echo "$hotplug_freq_1_1_sleep" > $hotplug_freq_1_1_tmp;
			echo "$hotplug_freq_2_0_sleep" > $hotplug_freq_2_0_tmp;
			echo "$hotplug_freq_2_1_sleep" > $hotplug_freq_2_1_tmp;
			echo "$hotplug_freq_3_0_sleep" > $hotplug_freq_3_0_tmp;
			echo "$hotplug_freq_3_1_sleep" > $hotplug_freq_3_1_tmp;
			echo "$hotplug_freq_4_0_sleep" > $hotplug_freq_4_0_tmp;
			echo "$hotplug_load_1_1_sleep" > $hotplug_load_1_1_tmp;
			echo "$hotplug_load_2_0_sleep" > $hotplug_load_2_0_tmp;
			echo "$hotplug_load_2_1_sleep" > $hotplug_load_2_1_tmp;
			echo "$hotplug_load_3_0_sleep" > $hotplug_load_3_0_tmp;
			echo "$hotplug_load_3_1_sleep" > $hotplug_load_3_1_tmp;
			echo "$hotplug_load_4_0_sleep" > $hotplug_load_4_0_tmp;
			echo "$hotplug_rq_1_1_sleep" > $hotplug_rq_1_1_tmp;
			echo "$hotplug_rq_2_0_sleep" > $hotplug_rq_2_0_tmp;
			echo "$hotplug_rq_2_1_sleep" > $hotplug_rq_2_1_tmp;
			echo "$hotplug_rq_3_0_sleep" > $hotplug_rq_3_0_tmp;
			echo "$hotplug_rq_3_1_sleep" > $hotplug_rq_3_1_tmp;
			echo "$hotplug_rq_4_0_sleep" > $hotplug_rq_4_0_tmp;
			echo "$maxcoreslimit_sleep" > $maxcoreslimit_tmp;
		# awake-settings
		elif [ "$state" == "awake" ]; then
			echo "$hotplug_sampling_rate" > $hotplug_sampling_rate_tmp;
			echo "$cpu_up_rate" > $cpu_up_rate_tmp;
			echo "$cpu_down_rate" > $cpu_down_rate_tmp;
			echo "$hotplug_freq_1_1" > $hotplug_freq_1_1_tmp;
			echo "$hotplug_freq_2_0" > $hotplug_freq_2_0_tmp;
			echo "$hotplug_freq_2_1" > $hotplug_freq_2_1_tmp;
			echo "$hotplug_freq_3_0" > $hotplug_freq_3_0_tmp;
			echo "$hotplug_freq_3_1" > $hotplug_freq_3_1_tmp;
			echo "$hotplug_freq_4_0" > $hotplug_freq_4_0_tmp;
			echo "$hotplug_load_1_1" > $hotplug_load_1_1_tmp;
			echo "$hotplug_load_2_0" > $hotplug_load_2_0_tmp;
			echo "$hotplug_load_2_1" > $hotplug_load_2_1_tmp;
			echo "$hotplug_load_3_0" > $hotplug_load_3_0_tmp;
			echo "$hotplug_load_3_1" > $hotplug_load_3_1_tmp;
			echo "$hotplug_load_4_0" > $hotplug_load_4_0_tmp;
			echo "$hotplug_rq_1_1" > $hotplug_rq_1_1_tmp;
			echo "$hotplug_rq_2_0" > $hotplug_rq_2_0_tmp;
			echo "$hotplug_rq_2_1" > $hotplug_rq_2_1_tmp;
			echo "$hotplug_rq_3_0" > $hotplug_rq_3_0_tmp;
			echo "$hotplug_rq_3_1" > $hotplug_rq_3_1_tmp;
			echo "$hotplug_rq_4_0" > $hotplug_rq_4_0_tmp;
			echo "$maxcoreslimit" > $maxcoreslimit_tmp;
		fi;

		log -p i -t $FILE_NAME "*** ALUCARD_HOTPLUG ***: enabled";
	fi;
}
# this needed for cpu hotplug tweaks apply from STweaks in real time
apply_hotplug="$2";
if [ "$apply_hotplug" == "changes" ] || [ "$cortexbrain_background_process" -eq "0" ]; then
	CPU_HOTPLUG_TWEAKS "awake";
fi;

CPU_GOV_TWEAKS()
{
	local state="$1";

	if [ "$cortexbrain_cpu" == "on" ]; then
		local SYSTEM_GOVERNOR=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor_all_cpus`;

		local sampling_rate_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/sampling_rate";
		if [ ! -e $sampling_rate_tmp ]; then
			sampling_rate_tmp="/dev/null";
		fi;

		local up_threshold_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold";
		if [ ! -e $up_threshold_tmp ]; then
			up_threshold_tmp="/dev/null";
		fi;

		local up_threshold_at_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold_at_min_freq";
		if [ ! -e $up_threshold_at_min_freq_tmp ]; then
			up_threshold_at_min_freq_tmp="/dev/null";
		fi;

		local up_threshold_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/up_threshold_min_freq";
		if [ ! -e $up_threshold_min_freq_tmp ]; then
			up_threshold_min_freq_tmp="/dev/null";
		fi;

		local inc_cpu_load_at_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/inc_cpu_load_at_min_freq";
		if [ ! -e $inc_cpu_load_at_min_freq_tmp ]; then
			inc_cpu_load_at_min_freq_tmp="/dev/null";
		fi;

		local dec_cpu_load_at_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/dec_cpu_load_at_min_freq";
		if [ ! -e $dec_cpu_load_at_min_freq_tmp ]; then
			dec_cpu_load_at_min_freq_tmp="/dev/null";
		fi;

		local down_threshold_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/down_threshold";
		if [ ! -e $down_threshold_tmp ]; then
			down_threshold_tmp="/dev/null";
		fi;

		local sampling_down_factor_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/sampling_down_factor";
		if [ ! -e $sampling_down_factor_tmp ]; then
			sampling_down_factor_tmp="/dev/null";
		fi;

		local down_differential_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/down_differential";
		if [ ! -e $down_differential_tmp ]; then
			down_differential_tmp="/dev/null";
		fi;

		local freq_for_responsiveness_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_for_responsiveness";
		if [ ! -e $freq_for_responsiveness_tmp ]; then
			freq_for_responsiveness_tmp="/dev/null";
		fi;

		local freq_responsiveness_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_responsiveness";
		if [ ! -e $freq_responsiveness_tmp ]; then
			freq_responsiveness_tmp="/dev/null";
		fi;

		local freq_for_responsiveness_max_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_for_responsiveness_max";
		if [ ! -e $freq_for_responsiveness_max_tmp ]; then
			freq_for_responsiveness_max_tmp="/dev/null";
		fi;

		local freq_step_at_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step_at_min_freq";
		if [ ! -e $freq_step_at_min_freq_tmp ]; then
			freq_step_at_min_freq_tmp="/dev/null";
		fi;

		local freq_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step";
		if [ ! -e $freq_step_tmp ]; then
			freq_step_tmp="/dev/null";
		fi;

		local freq_step_dec_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step_dec";
		if [ ! -e $freq_step_dec_tmp ]; then
			freq_step_dec_tmp="/dev/null";
		fi;

		local freq_step_dec_at_max_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_step_dec_at_max_freq";
		if [ ! -e $freq_step_dec_at_max_freq_tmp ]; then
			freq_step_dec_at_max_freq_tmp="/dev/null";
		fi;

		local inc_cpu_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/inc_cpu_load";
		if [ ! -e $inc_cpu_load_tmp ]; then
			inc_cpu_load_tmp="/dev/null";
		fi;

		local dec_cpu_load_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/dec_cpu_load";
		if [ ! -e $dec_cpu_load_tmp ]; then
			dec_cpu_load_tmp="/dev/null";
		fi;

		local freq_up_brake_at_min_freq_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_up_brake_at_min_freq";
		if [ ! -e $freq_up_brake_at_min_freq_tmp ]; then
			freq_up_brake_at_min_freq_tmp="/dev/null";
		fi;

		local freq_up_brake_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/freq_up_brake";
		if [ ! -e $freq_up_brake_tmp ]; then
			freq_up_brake_tmp="/dev/null";
		fi;

		# merge up_threshold_at_min_freq & up_threshold_min_freq => up_threshold_at_min_freq_tmp
		if [ $up_threshold_at_min_freq_tmp == "/dev/null" ] && [ $up_threshold_min_freq_tmp != "/dev/null" ]; then
			up_threshold_at_min_freq_tmp=$up_threshold_min_freq_tmp;
		fi;

		# merge freq_for_responsiveness_tmp & freq_responsiveness_tmp => freq_for_responsiveness_tmp
		# if [ $freq_for_responsiveness_tmp == "/dev/null" ] && [ $freq_responsiveness_tmp != "/dev/null" ]; then
		# 	freq_for_responsiveness_tmp=$freq_responsiveness_tmp;
		# fi;

		local pump_inc_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_inc_step";
		if [ ! -e $pump_inc_step_tmp ]; then
			pump_inc_step_tmp="/dev/null";
		fi;

		local pump_dec_step_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_dec_step";
		if [ ! -e $pump_dec_step_tmp ]; then
			pump_dec_step_tmp="/dev/null";
		fi;

		# sleep-settings
		if [ "$state" == "sleep" ]; then
			echo "$sampling_rate_sleep" > $sampling_rate_tmp;
			echo "$up_threshold_sleep" > $up_threshold_tmp;
			echo "$up_threshold_at_min_freq_sleep" > $up_threshold_at_min_freq_tmp;
			echo "$inc_cpu_load_at_min_freq_sleep" > $inc_cpu_load_at_min_freq_tmp;
			echo "$dec_cpu_load_at_min_freq_sleep" > $dec_cpu_load_at_min_freq_tmp;
			echo "$down_threshold_sleep" > $down_threshold_tmp;
			echo "$sampling_down_factor_sleep" > $sampling_down_factor_tmp;
			echo "$down_differential_sleep" > $down_differential_tmp;
			echo "$freq_step_at_min_freq_sleep" > $freq_step_at_min_freq_tmp;
			echo "$freq_step_sleep" > $freq_step_tmp;
			echo "$freq_step_dec_sleep" > $freq_step_dec_tmp;
			echo "$freq_step_dec_at_max_freq_sleep" > $freq_step_dec_at_max_freq_tmp;
			echo "$freq_for_responsiveness_sleep" > $freq_for_responsiveness_tmp;
			echo "$freq_responsiveness_sleep" > $freq_responsiveness_tmp;
			echo "$freq_for_responsiveness_max_sleep" > $freq_for_responsiveness_max_tmp;
			echo "$inc_cpu_load_sleep" > $inc_cpu_load_tmp;
			echo "$dec_cpu_load_sleep" > $dec_cpu_load_tmp;
			echo "$freq_up_brake_at_min_freq_sleep" > $freq_up_brake_at_min_freq_tmp;
			echo "$freq_up_brake_sleep" > $freq_up_brake_tmp;
			echo "$pump_inc_step_sleep" > $pump_inc_step_tmp;
			echo "$pump_dec_step_sleep" > $pump_dec_step_tmp;
			CPU_HOTPLUG_TWEAKS "sleep";
		# awake-settings
		elif [ "$state" == "awake" ]; then
			echo "$sampling_rate" > $sampling_rate_tmp;
			echo "$up_threshold" > $up_threshold_tmp;
			echo "$up_threshold_at_min_freq" > $up_threshold_at_min_freq_tmp;
			echo "$inc_cpu_load_at_min_freq" > $inc_cpu_load_at_min_freq_tmp;
			echo "$dec_cpu_load_at_min_freq" > $dec_cpu_load_at_min_freq_tmp;
			echo "$down_threshold" > $down_threshold_tmp;
			echo "$sampling_down_factor" > $sampling_down_factor_tmp;
			echo "$down_differential" > $down_differential_tmp;
			echo "$freq_step_at_min_freq" > $freq_step_at_min_freq_tmp;
			echo "$freq_step" > $freq_step_tmp;
			echo "$freq_step_dec" > $freq_step_dec_tmp;
			echo "$freq_step_dec_at_max_freq" > $freq_step_dec_at_max_freq_tmp;
			echo "$freq_for_responsiveness" > $freq_for_responsiveness_tmp;
			echo "$freq_responsiveness" > $freq_responsiveness_tmp;
			echo "$freq_for_responsiveness_max" > $freq_for_responsiveness_max_tmp;
			echo "$inc_cpu_load" > $inc_cpu_load_tmp;
			echo "$dec_cpu_load" > $dec_cpu_load_tmp;
			echo "$freq_up_brake_at_min_freq" > $freq_up_brake_at_min_freq_tmp;
			echo "$freq_up_brake" > $freq_up_brake_tmp;
			echo "$pump_inc_step" > $pump_inc_step_tmp;
			echo "$pump_dec_step" > $pump_dec_step_tmp;
			CPU_HOTPLUG_TWEAKS "awake";
		fi;

		log -p i -t $FILE_NAME "*** CPU_GOV_TWEAKS: $state ***: enabled";

		return 1;
	else
		return 0;
	fi;
}
# this needed for cpu tweaks apply from STweaks in real time
apply_cpu="$2";
if [ "$apply_cpu" == "update" ] || [ "$cortexbrain_background_process" -eq "0" ]; then
	CPU_GOV_TWEAKS "awake";
fi;

# ==============================================================
# GLOBAL-FUNCTIONS
# ==============================================================

WIFI_SET()
{
	local state="$1";

	if [ "$state" == "off" ]; then
		service call wifi 13 i32 0 > /dev/null;
		svc wifi disable;
		echo "1" > $WIFI_HELPER_AWAKE;
	elif [ "$state" == "on" ]; then
		service call wifi 13 i32 1 > /dev/null;
		svc wifi enable;
	fi;

	log -p i -t $FILE_NAME "*** WIFI ***: $state";
}

WIFI()
{
	local state="$1";

	if [ "$state" == "sleep" ]; then
		if [ "$cortexbrain_auto_tweak_wifi" == "on" ]; then
			if [ -e /sys/module/dhd/initstate ]; then
				if [ "$cortexbrain_auto_tweak_wifi_sleep_delay" -eq "0" ]; then
					WIFI_SET "off";
				else
					(
						echo "0" > $WIFI_HELPER_TMP;
						# screen time out but user want to keep it on and have wifi
						sleep 10;
						if [ `cat $WIFI_HELPER_TMP` -eq "0" ]; then
							# user did not turned screen on, so keep waiting
							local SLEEP_TIME_WIFI=$(( $cortexbrain_auto_tweak_wifi_sleep_delay - 10 ));
							log -p i -t $FILE_NAME "*** DISABLE_WIFI $cortexbrain_auto_tweak_wifi_sleep_delay Sec Delay Mode ***";
							sleep $SLEEP_TIME_WIFI;
							if [ `cat $WIFI_HELPER_TMP` -eq "0" ]; then
								# user left the screen off, then disable wifi
								WIFI_SET "off";
							fi;
						fi;
					)&
				fi;
			else
				echo "0" > $WIFI_HELPER_AWAKE;
			fi;
		fi;
	elif [ "$state" == "awake" ]; then
		if [ "$cortexbrain_auto_tweak_wifi" == "on" ]; then
			echo "1" > $WIFI_HELPER_TMP;
			if [ `cat $WIFI_HELPER_AWAKE` -eq "1" ]; then
				WIFI_SET "on";
			fi;
		fi;
	fi;
}

MOBILE_DATA_SET()
{
	local state="$1";

	if [ "$state" == "off" ]; then
		svc data disable;
		echo "1" > $MOBILE_HELPER_AWAKE;
	elif [ "$state" == "on" ]; then
		svc data enable;
	fi;

	log -p i -t $FILE_NAME "*** MOBILE DATA ***: $state";
}

MOBILE_DATA_STATE()
{
	DATA_STATE_CHECK=0;

	if [ $DUMPSYS_STATE -eq "1" ]; then
		local DATA_STATE=`echo "$TELE_DATA" | awk '/mDataConnectionState/ {print $1}'`;

		if [ "$DATA_STATE" != "mDataConnectionState=0" ]; then
			DATA_STATE_CHECK=1;
		fi;
	fi;
}

MOBILE_DATA()
{
	local state="$1";

	if [ "$cortexbrain_auto_tweak_mobile" == "on" ]; then
		if [ "$state" == "sleep" ]; then
			MOBILE_DATA_STATE;
			if [ "$DATA_STATE_CHECK" -eq "1" ]; then
				if [ "$cortexbrain_auto_tweak_mobile_sleep_delay" -eq "0" ]; then
					MOBILE_DATA_SET "off";
				else
					(
						echo "0" > $MOBILE_HELPER_TMP;
						# screen time out but user want to keep it on and have mobile data
						sleep 10;
						if [ `cat $MOBILE_HELPER_TMP` -eq "0" ]; then
							# user did not turned screen on, so keep waiting
							local SLEEP_TIME_DATA=$(( $cortexbrain_auto_tweak_mobile_sleep_delay - 10 ));
							log -p i -t $FILE_NAME "*** DISABLE_MOBILE $cortexbrain_auto_tweak_mobile_sleep_delay Sec Delay Mode ***";
							sleep $SLEEP_TIME_DATA;
							if [ `cat $MOBILE_HELPER_TMP` -eq "0" ]; then
								# user left the screen off, then disable mobile data
								MOBILE_DATA_SET "off";
							fi;
						fi;
					)&
				fi;
			else
				echo "0" > $MOBILE_HELPER_AWAKE;
			fi;
		elif [ "$state" == "awake" ]; then
			echo "1" > $MOBILE_HELPER_TMP;
			if [ `cat $MOBILE_HELPER_AWAKE` -eq "1" ]; then
				MOBILE_DATA_SET "on";
			fi;
		fi;
	fi;
}

LOGGER()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		if [ "$android_logger" == "auto" ] || [ "$android_logger" == "debug" ]; then
			echo "1" > /sys/module/logger/parameters/log_enabled;
		elif [ "$android_logger" == "disabled" ]; then
			echo "0" > /sys/module/logger/parameters/log_enabled;
		fi;
	elif [ "$state" == "sleep" ]; then
		if [ "$android_logger" == "auto" ] || [ "$android_logger" == "disabled" ]; then
			echo "0" > /sys/module/logger/parameters/log_enabled;
		fi;
	fi;

	log -p i -t $FILE_NAME "*** LOGGER ***: $state";
}

# mount sdcard and emmc, if usb mass storage is used
MOUNT_SD_CARD()
{
	if [ "$auto_mount_sd" == "on" ]; then
		if [ -e /dev/block/vold/179:32 ]; then
			echo "/dev/block/vold/179:32" > /sys/devices/virtual/android_usb/android0/f_mass_storage/lun0/file;
		fi;

		log -p i -t $FILE_NAME "*** MOUNT_SD_CARD ***";
	fi;
}
# run dual mount on boot
apply_cpu="$2";
if [ "$apply_cpu" != "update" ]; then
	MOUNT_SD_CARD;
fi;

CENTRAL_CPU_FREQ()
{
	local state="$1";

	local tmp_max_freq=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq_all_cpus`;
	local tmp_min_freq=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq_all_cpus`;
	# Alucard hotplug
	local alucard_value_tmp=`cat /sys/kernel/alucard_hotplug/hotplug_enable`;
	local maxcoreslimit_tmp="/sys/kernel/alucard_hotplug/maxcoreslimit";

	if [ "$cortexbrain_cpu" == "on" ]; then
		MAX_FREQ=`echo $scaling_max_freq_all_cpus`;
		if [ "$state" == "wake_boost" ] && [ "$wakeup_boost" -ge "0" ]; then
			echo "$MAX_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq_all_cpus;
			echo "$MAX_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq_all_cpus;
			if [ "$alucard_value_tmp" -eq "1" ]; then
				if [ ! -e $maxcoreslimit_tmp ]; then
					maxcoreslimit_tmp="/dev/null";
				fi;
				echo "$maxcoreslimit" > $maxcoreslimit_tmp;
			fi;
		elif [ "$state" == "awake_normal" ]; then
			echo "$MAX_FREQ" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq_all_cpus;
			echo "$scaling_min_freq_all_cpus" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq_all_cpus;
		elif [ "$state" == "standby_freq" ]; then
			echo "$standby_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq_all_cpus;
		elif [ "$state" == "sleep_freq" ]; then
			echo "$scaling_min_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq_all_cpus;
			echo "$scaling_max_suspend_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq_all_cpus;
		elif [ "$state" == "sleep_call" ]; then
			echo "$standby_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq_all_cpus;
			# brain cooking prevention during call
			echo "$scaling_max_oncall_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq_all_cpus;
		fi;

		log -p i -t $FILE_NAME "*** CENTRAL_CPU_FREQ: $state ***: done";
	else
		log -p i -t $FILE_NAME "*** CENTRAL_CPU_FREQ: NOT CHANGED ***: done";
	fi;
}

# boost CPU power for fast and no lag wakeup
MEGA_BOOST_CPU_TWEAKS()
{
	if [ "$cortexbrain_cpu" == "on" ]; then
		CENTRAL_CPU_FREQ "wake_boost";

		log -p i -t "$FILE_NAME" "*** MEGA_BOOST_CPU_TWEAKS ***";
	else
		echo "$scaling_max_freq" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq_all_cpus;
	fi;
}

BOOST_DELAY()
{
	# check if ROM booting now, then don't wait - creation and deletion of $DATA_DIR/booting @> /sbin/ext/post-init.sh
	if [ "$wakeup_boost" -gt "0" ] && [ ! -e "$DATA_DIR"/booting ]; then
		log -p i -t "$FILE_NAME" "*** BOOST_DELAY: ${wakeup_boost}sec ***";
		sleep "$wakeup_boost";
	fi;
}

# set swappiness in case that no root installed, and zram used or disk swap used
SWAPPINESS()
{
	local SWAP_CHECK=`free | grep Swap | awk '{ print $2 }'`;

	if [ "$SWAP_CHECK" -eq "0" ]; then
		echo "0" > /proc/sys/vm/swappiness;
	else
		echo "$swappiness" > /proc/sys/vm/swappiness;
	fi;

	log -p i -t $FILE_NAME "*** SWAPPINESS: $swappiness ***";
}
SWAPPINESS;

NET()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		echo "3" > /proc/sys/net/ipv4/tcp_keepalive_probes; # default: 3
		echo "1200" > /proc/sys/net/ipv4/tcp_keepalive_time; # default: 7200s
		echo "10" > /proc/sys/net/ipv4/tcp_keepalive_intvl; # default: 75s
		echo "10" > /proc/sys/net/ipv4/tcp_retries2; # default: 15
	elif [ "$state" == "sleep" ]; then
		echo "2" > /proc/sys/net/ipv4/tcp_keepalive_probes;
		echo "300" > /proc/sys/net/ipv4/tcp_keepalive_time;
		echo "5" > /proc/sys/net/ipv4/tcp_keepalive_intvl;
		echo "5" > /proc/sys/net/ipv4/tcp_retries2;
	fi;

	log -p i -t $FILE_NAME "*** NET ***: $state";
}

IO_SCHEDULER()
{
	if [ "$cortexbrain_io" == "on" ]; then

		local state="$1";
		local sys_mmc0_scheduler_tmp="/sys/block/mmcblk0/queue/scheduler";
		local sys_mmc1_scheduler_tmp="/sys/block/mmcblk1/queue/scheduler";
		local tmp_scheduler="";
		local tmp_scheduler_sd="";
		local new_scheduler="";
		local new_scheduler_sd="";

		if [ -e $sys_mmc1_scheduler_tmp ]; then
			sys_mmc1_scheduler_tmp="/dev/null";
		fi;

		if [ "$state" == "awake" ]; then
			new_scheduler=$internal_iosched;
			new_scheduler_sd=$sd_iosched;
		elif [ "$state" == "sleep" ]; then
			new_scheduler=$internal_iosched_sleep;
			new_scheduler_sd=$sd_iosched_sleep;
		fi;

		tmp_scheduler=`cat $sys_mmc0_scheduler_tmp`;

		if [ "$tmp_scheduler" != "$new_scheduler" ]; then
			echo "$new_scheduler" > $sys_mmc0_scheduler_tmp;
		fi;

		log -p i -t $FILE_NAME "*** INTERNAL IO_SCHEDULER: $state - $new_scheduler ***: done";

		tmp_scheduler_sd=`cat $sys_mmc1_scheduler_tmp`;

		if [ "$tmp_scheduler_sd" != "$new_scheduler_sd" ]; then
			echo "$new_scheduler_sd" > $sys_mmc1_scheduler_tmp;
		fi;

		log -p i -t $FILE_NAME "*** EXTERNAL IO_SCHEDULER: $state - $new_scheduler_sd ***: done";

		# set I/O Tweaks again ...
		IO_TWEAKS;
	else
		log -p i -t $FILE_NAME "*** Cortex IO_SCHEDULER: Disabled ***";
	fi;
}

CPU_GOVERNOR()
{
	local state="$1";
	local scaling_governor_all_cpus_tmp="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor_all_cpus";
	local tmp_governor=`cat $scaling_governor_all_cpus_tmp`;

	if [ "$cortexbrain_cpu" == "on" ]; then
		if [ "$state" == "awake" ]; then
			if [ "$tmp_governor" != $scaling_governor_all_cpus ]; then
				echo "$scaling_governor_all_cpus" > $scaling_governor_tmp;
			fi;
		elif [ "$state" == "sleep" ]; then
			if [ "$tmp_governor" != $scaling_governor_all_cpus_sleep ]; then
				echo "$scaling_governor_all_cpus_sleep" > $scaling_governor_tmp;
			fi;
		fi;

		local USED_GOV_NOW=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor_all_cpus`;

		log -p i -t $FILE_NAME "*** CPU_GOVERNOR: set $state GOV $USED_GOV_NOW ***: done";
	else
		log -p i -t $FILE_NAME "*** CPU_GOVERNOR: NO CHANGED ***: done";
	fi;
}

CALL_STATE()
{
	if [ "$DUMPSYS_STATE" -eq "1" ]; then

		# check the call state, not on call = 0, on call = 2
		local state_tmp=`echo "$TELE_DATA" | awk '/mCallState/ {print $1}'`;

		if [ "$state_tmp" != "mCallState=0" ]; then
			NOW_CALL_STATE=1;
		else
			NOW_CALL_STATE=0;
		fi;

		log -p i -t $FILE_NAME "*** CALL_STATE: $NOW_CALL_STATE ***";
	else
		NOW_CALL_STATE=0;
	fi;
}

VIBRATE_FIX()
{
	echo "$pwm_value" > /sys/devices/virtual/timed_output/vibrator/pwm_value;

	log -p i -t $FILE_NAME "*** VIBRATE_FIX: $pwm_value ***";
}

MOUNT_FIX()
{
	local CHECK_SYSTEM=`mount | grep /system | grep ro | wc -l`;
	local CHECK_DATA=`mount | grep /data | cut -c 26-27 | grep ro | grep -v ec | wc -l`;

	if [ "$CHECK_SYSTEM" -eq "1" ]; then
		mount -o remount,rw /system;
	fi;
	if [ "$CHECK_DATA" -eq "1" ]; then
		mount -o remount,rw /data;
	fi;
	if [ "$EXTERNAL_SDCARD_CM" -eq "1" ]; then
		mount -o remount,rw,nosuid,nodev,noexec /storage/sdcard1;
	elif [ "$EXTERNAL_SDCARD_STOCK" -eq "1" ]; then
		mount -o remount,rw,nosuid,nodev,noexec /storage/extSdCard;
	fi;
}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	# Do not touch this
	CALL_STATE;
	VIBRATE_FIX;
	MOUNT_SD_CARD;

	# Check call state, if on call dont sleep
	if [ "$NOW_CALL_STATE" -eq "1" ]; then
		CENTRAL_CPU_FREQ "awake_normal";
		NOW_CALL_STATE=0;
	else
		# not on call, check if was powerd by USB on sleep, or didnt sleep at all
		if [ "$WAS_IN_SLEEP_MODE" -eq "1" ] && [ "$USB_POWER" -eq "0" ]; then
			CPU_GOVERNOR "awake";
			CPU_GOV_TWEAKS "awake";
			MEGA_BOOST_CPU_TWEAKS;
			LOGGER "awake";
			# NET "awake";
			MOBILE_DATA "awake";
			WIFI "awake";
			IO_SCHEDULER "awake";

			BOOST_DELAY;

			CENTRAL_CPU_FREQ "awake_normal";
			MOUNT_FIX;
		else
			# Was powered by USB, and half sleep
			MEGA_BOOST_CPU_TWEAKS;

			BOOST_DELAY;

			CENTRAL_CPU_FREQ "awake_normal";
			MOUNT_FIX;
			USB_POWER=0;

			log -p i -t $FILE_NAME "*** USB_POWER_WAKE: done ***";
		fi;
		# Didn't sleep, and was not powered by USB
	fi;
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	WAS_IN_SLEEP_MODE=0;

	# we only read the config when the screen turns off ...
	PROFILE=`cat $DATA_DIR/.active.profile`;
	. $DATA_DIR/${PROFILE}.profile;

	# we only read tele-data when the screen turns off ...
	if [ "$DUMPSYS_STATE" -eq "1" ]; then
		TELE_DATA=`dumpsys telephony.registry`;
	fi;

	# Check call state
	CALL_STATE;

	# Check Early Wakeup
	local TMP_EARLY_WAKEUP=`cat /tmp/early_wakeup`;

	# check if early_wakeup, or we on call
	if [ "$TMP_EARLY_WAKEUP" -eq "0" ] && [ "$NOW_CALL_STATE" -eq "0" ]; then
		WAS_IN_SLEEP_MODE=1;
		CENTRAL_CPU_FREQ "standby_freq";
		SWAPPINESS;

		# for devs use, if debug is on, then finish full sleep with usb connected
		if [ "$android_logger" == "debug" ]; then
			CHARGING=1;
		else
			CHARGING=`cat /sys/class/power_supply/battery/batt_charging_source`;
		fi;

		# check if we powered by USB, if not sleep
		if [ "$CHARGING" -eq "1" ]; then
			CPU_GOVERNOR "sleep";
			CENTRAL_CPU_FREQ "sleep_freq";
			CPU_GOV_TWEAKS "sleep";
			IO_SCHEDULER "sleep";
			# NET "sleep";
			WIFI "sleep";
			BATTERY_TWEAKS;
			MOBILE_DATA "sleep";

			log -p i -t $FILE_NAME "*** SLEEP mode ***";

			LOGGER "sleep";
		else
			# Powered by USB
			USB_POWER=1;
			log -p i -t $FILE_NAME "*** SLEEP mode: USB CABLE CONNECTED! No real sleep mode! ***";
		fi;
	else
		# Check if on call
		if [ "$NOW_CALL_STATE" -eq "1" ]; then
			CENTRAL_CPU_FREQ "sleep_call";
			NOW_CALL_STATE=1;

			log -p i -t $FILE_NAME "*** on call: SLEEP aborted! ***";
		else
			# Early Wakeup detected
			log -p i -t $FILE_NAME "*** early wake up: SLEEP aborted! ***";
		fi;
	fi;

	# kill wait_for_fb_wake generated by /sbin/ext/wakecheck.sh
	pkill -f "cat /sys/power/wait_for_fb_wake"
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
cortexbrain_background_process=1;

if [ "$cortexbrain_background_process" -eq "1" ] && [ `pgrep -f "cat /sys/power/wait_for_fb_sleep" | wc -l` -eq "0" ] && [ `pgrep -f "cat /sys/power/wait_for_fb_wake" | wc -l` -eq "0" ]; then
	(while [ 1 ]; do
		# AWAKE State. all system ON
		cat /sys/power/wait_for_fb_wake > /dev/null 2>&1;
		AWAKE_MODE;
		sleep 2;

		# SLEEP state. All system to power save
		cat /sys/power/wait_for_fb_sleep > /dev/null 2>&1;
		sleep 2;
		/sbin/ext/wakecheck.sh;
		SLEEP_MODE;
	done &);
else
	if [ "$cortexbrain_background_process" -eq "0" ]; then
		echo "Cortex background disabled!"
	else
		echo "Cortex background process already running!";
	fi;
fi;

# ==============================================================
# Logic Explanations
#
# This script will manipulate all the system / cpu / battery behavior
# Based on chosen STWEAKS profile+tweaks and based on SCREEN ON/OFF state.
#
# When User select battery/default profile all tuning will be toward battery save.
# But user loose performance -20% and get more stable system and more battery left.
#
# When user select performance profile, tuning will be to max performance on screen ON.
# When screen OFF all tuning switched to max power saving. as with battery profile,
# So user gets max performance and max battery save but only on screen OFF.
#
# This script change governors and tuning for them on the fly.
# Also switch on/off hotplug CPU core based on screen on/off.
# This script reset battery stats when battery is 100% charged.
# This script tune Network and System VM settings and ROM settings tuning.
# This script changing default MOUNT options and I/O tweaks for all flash disks and ZRAM.
#
# TODO: add more description, explanations & default vaules ...
#
