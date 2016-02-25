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

BB=/sbin/busybox

# change mode for /tmp/
ROOTFS_MOUNT=$(mount | grep rootfs | cut -c26-27 | grep -c rw)
if [ "$ROOTFS_MOUNT" -eq "0" ]; then
	mount -o remount,rw /;
fi;
chmod -R 777 /tmp/;

# ==============================================================
# GLOBAL VARIABLES || without "local" also a variable in a function is global
# ==============================================================

FILE_NAME=$0;
# (since we don't have the recovery source code I can't change the ".alucard" dir, so just leave it there for history)
DATA_DIR=/data/.alucard;
USB_POWER=0;

# ==============================================================
# INITIATE
# ==============================================================

# For CHARGER CHECK.
echo "1" > /data/alu_cortex_sleep;

# get values from profile
PROFILE=$(cat $DATA_DIR/.active.profile);
. "$DATA_DIR"/"$PROFILE".profile;

# ==============================================================
# I/O-TWEAKS
# ==============================================================
IO_TWEAKS()
{
	if [ "$cortexbrain_io" == "on" ]; then

		local i="";

		local MMC=$(find /sys/block/mmcblk0*);
		for i in $MMC; do
			echo "$internal_iosched" > "$i"/queue/scheduler;
			echo "0" > "$i"/queue/rotational;
			echo "0" > "$i"/queue/iostats;
			echo "2" > "$i"/queue/nomerges;
		done;

		# This controls how many requests may be allocated
		# in the block layer for read or write requests.
		# Note that the total allocated number may be twice
		# this amount, since it applies only to reads or writes
		# (not the accumulated sum).
		echo "128" > /sys/block/mmcblk0/queue/nr_requests; # default: 128

		# our storage is 16/32GB, best is 1024KB readahead
		# see https://github.com/Keff/samsung-kernel-msm7x30/commit/a53f8445ff8d947bd11a214ab42340cc6d998600#L1R627
		echo "$intsd_read_ahead_kb" > /sys/block/mmcblk0/queue/read_ahead_kb;
		echo "$intsd_read_ahead_kb" > /sys/block/mmcblk0/bdi/read_ahead_kb;

		echo "$extsd_read_ahead_kb" > /sys/block/mmcblk1/queue/read_ahead_kb;

		echo "45" > /proc/sys/fs/lease-break-time;

		log -p i -t "$FILE_NAME" "*** IO_TWEAKS ***: enabled";
	else
		return 0;
	fi;
}
IO_TWEAKS;

# ==============================================================
# KERNEL-TWEAKS
# ==============================================================
KERNEL_TWEAKS()
{
	if [ "$cortexbrain_kernel_tweaks" == "on" ]; then
		echo "0" > /proc/sys/vm/oom_kill_allocating_task;
		echo "0" > /proc/sys/vm/panic_on_oom;
		echo "30" > /proc/sys/kernel/panic;
		echo "0" > /proc/sys/kernel/panic_on_oops;

		log -p i -t "$FILE_NAME" "*** KERNEL_TWEAKS ***: enabled";
	else
		echo "kernel_tweaks disabled";
	fi;
}
KERNEL_TWEAKS;

# ==============================================================
# SYSTEM-TWEAKS
# ==============================================================
SYSTEM_TWEAKS()
{
	if [ "$cortexbrain_system" == "on" ]; then
		setprop windowsmgr.max_events_per_sec 240;

		log -p i -t "$FILE_NAME" "*** SYSTEM_TWEAKS ***: enabled";
	else
		echo "system_tweaks disabled";
	fi;
}
SYSTEM_TWEAKS;

# ==============================================================
# MEMORY-TWEAKS
# ==============================================================
MEMORY_TWEAKS()
{
	if [ "$cortexbrain_memory" == "on" ]; then
		echo "$dirty_background_ratio" > /proc/sys/vm/dirty_background_ratio; # default: 20
		echo "$dirty_ratio" > /proc/sys/vm/dirty_ratio; # default: 25
		echo "4" > /proc/sys/vm/min_free_order_shift; # default: 4
		echo "1" > /proc/sys/vm/overcommit_memory; # default: 1
		echo "50" > /proc/sys/vm/overcommit_ratio; # default: 50
		echo "3" > /proc/sys/vm/page-cluster; # default: 3
		#echo "8192" > /proc/sys/vm/min_free_kbytes; #default: 2572
		# mem calc here in pages. so 16384 x 4 = 64MB reserved for fast access by kernel and VM
		echo "32768" > /proc/sys/vm/mmap_min_addr; #default: 32768

		log -p i -t "$FILE_NAME" "*** MEMORY_TWEAKS ***: enabled";
	else
		return 0;
	fi;
}
MEMORY_TWEAKS;

# ==============================================================
# CPU-TWEAKS
# ==============================================================

CPU_HOTPLUG_TWEAKS()
{
	local state="$1";

	if [ "$cpuhotplugging" -eq "1" ]; then
		if [ -e /system/bin/mpdecision ]; then
			if [ "$(pgrep -f "/system/bin/mpdecision" | wc -l)" -eq "0" ]; then
				/system/bin/start mpdecision
				$BB renice -n -20 -p "$(pgrep -f "/system/bin/start mpdecision")";
			fi;
		fi;
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "0" ]; then
			echo "1" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
			if [ -e /system/bin/mpdecision ]; then
				/system/bin/stop mpdecision
				/system/bin/start mpdecision
				$BB renice -n -20 -p "$(pgrep -f "/system/bin/start mpdecision")";
				echo "10" > /sys/devices/system/cpu/cpu0/rq-stats/run_queue_poll_ms;
			else
				# Some !Stupid APP! changed mpdecision name, not my problem. use msm hotplug!
				echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
				echo "1" > /sys/module/msm_hotplug/msm_enabled;
			fi;
		fi;

		log -p i -t "$FILE_NAME" "*** MSM_MPDECISION ***: enabled";
	elif [ "$cpuhotplugging" -eq "2" ]; then
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "0" ]; then
			echo "1" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
		if [ -e /system/bin/mpdecision ]; then
			/system/bin/stop mpdecision
		fi;

		# tune-settings
		if [ "$state" == "tune" ]; then
			echo "$min_cpus_online" > /sys/kernel/intelli_plug/min_cpus_online;
			echo "$max_cpus_online" > /sys/kernel/intelli_plug/max_cpus_online;
		fi;

		log -p i -t "$FILE_NAME" "*** INTELLI_PLUG ***: enabled";
	elif [ "$cpuhotplugging" -eq "3" ]; then
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "0" ]; then
			echo "1" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
		if [ -e /system/bin/mpdecision ]; then
			/system/bin/stop mpdecision
		fi;

		# tune-settings
		if [ "$state" == "tune" ]; then
			echo "$hotplug_sampling_rate" > /sys/kernel/alucard_hotplug/hotplug_sampling_rate;
			echo "$hotplug_rate_1_1" > /sys/kernel/alucard_hotplug/hotplug_rate_1_1;
			echo "$hotplug_rate_2_0" > /sys/kernel/alucard_hotplug/hotplug_rate_2_0;
			echo "$hotplug_rate_2_1" > /sys/kernel/alucard_hotplug/hotplug_rate_2_1;
			echo "$hotplug_rate_3_0" > /sys/kernel/alucard_hotplug/hotplug_rate_3_0;
			echo "$hotplug_rate_3_1" > /sys/kernel/alucard_hotplug/hotplug_rate_3_1;
			echo "$hotplug_rate_4_0" > /sys/kernel/alucard_hotplug/hotplug_rate_4_0;
			echo "$hotplug_freq_1_1" > /sys/kernel/alucard_hotplug/hotplug_freq_1_1;
			echo "$hotplug_freq_2_0" > /sys/kernel/alucard_hotplug/hotplug_freq_2_0;
			echo "$hotplug_freq_2_1" > /sys/kernel/alucard_hotplug/hotplug_freq_2_1;
			echo "$hotplug_freq_3_0" > /sys/kernel/alucard_hotplug/hotplug_freq_3_0;
			echo "$hotplug_freq_3_1" > /sys/kernel/alucard_hotplug/hotplug_freq_3_1;
			echo "$hotplug_freq_4_0" > /sys/kernel/alucard_hotplug/hotplug_freq_4_0;
			echo "$hotplug_load_1_1" > /sys/kernel/alucard_hotplug/hotplug_load_1_1;
			echo "$hotplug_load_2_0" > /sys/kernel/alucard_hotplug/hotplug_load_2_0;
			echo "$hotplug_load_2_1" > /sys/kernel/alucard_hotplug/hotplug_load_2_1;
			echo "$hotplug_load_3_0" > /sys/kernel/alucard_hotplug/hotplug_load_3_0;
			echo "$hotplug_load_3_1" > /sys/kernel/alucard_hotplug/hotplug_load_3_1;
			echo "$hotplug_load_4_0" > /sys/kernel/alucard_hotplug/hotplug_load_4_0;
			echo "$hotplug_rq_1_1" > /sys/kernel/alucard_hotplug/hotplug_rq_1_1;
			echo "$hotplug_rq_2_0" > /sys/kernel/alucard_hotplug/hotplug_rq_2_0;
			echo "$hotplug_rq_2_1" > /sys/kernel/alucard_hotplug/hotplug_rq_2_1;
			echo "$hotplug_rq_3_0" > /sys/kernel/alucard_hotplug/hotplug_rq_3_0;
			echo "$hotplug_rq_3_1" > /sys/kernel/alucard_hotplug/hotplug_rq_3_1;
			echo "$hotplug_rq_4_0" > /sys/kernel/alucard_hotplug/hotplug_rq_4_0;
			echo "$maxcoreslimit" > /sys/kernel/alucard_hotplug/maxcoreslimit;
			echo "$maxcoreslimit_sleep" > /sys/kernel/alucard_hotplug/maxcoreslimit_sleep;
			echo "$min_cpus_online" > /sys/kernel/alucard_hotplug/min_cpus_online;
		fi;

		log -p i -t "$FILE_NAME" "*** ALUCARD_HOTPLUG ***: enabled";
	elif [ "$cpuhotplugging" -eq "4" ]; then
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "0" ]; then
			echo "1" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
		if [ -e /system/bin/mpdecision ]; then
			/system/bin/stop mpdecision
		fi;

		# tune-settings
		if [ "$state" == "tune" ]; then
			echo "$min_cpus_online" > /sys/module/msm_hotplug/min_cpus_online;
			echo "$max_cpus_online" > /sys/module/msm_hotplug/max_cpus_online;
		fi;

		log -p i -t "$FILE_NAME" "*** MSM_HOTPLUG ***: enabled";
	fi;
}

FORCE_CPUS_ONOFF()
{
	local state="$1";

	if [ "$state" == "online" ]; then
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
		if [ -e /system/bin/mpdecision ]; then
			/system/bin/stop mpdecision
		fi;
		echo "1" > /sys/devices/system/cpu/cpu1/online;
		echo "1" > /sys/devices/system/cpu/cpu2/online;
		echo "1" > /sys/devices/system/cpu/cpu3/online;
	elif [ "$state" == "offline" ]; then
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_enable;
		fi;
		if [ -e /system/bin/mpdecision ]; then
			/system/bin/stop mpdecision
		fi;
		echo "0" > /sys/devices/system/cpu/cpu1/online;
		echo "0" > /sys/devices/system/cpu/cpu2/online;
		echo "0" > /sys/devices/system/cpu/cpu3/online;
	fi;
}

CPU_GOV_TWEAKS()
{
	local state="$1";

	if [ "$cortexbrain_cpu" == "on" ]; then
		local SYSTEM_GOVERNOR_PATH=$(find /sys/devices/system/cpu/cpufreq/all_cpus/scaling_governor_cpu*);
		local i="";
		local PREV_SYSTEM_GOVERNOR="";
		
		# tune-settings
		if [ "$state" == "tune" ]; then
			#put online all cpus for applying cpu governor parameters
			FORCE_CPUS_ONOFF "online";

			for i in $SYSTEM_GOVERNOR_PATH; do
				local SYSTEM_GOVERNOR=$(cat "$i");
				if [ "$(echo "$PREV_SYSTEM_GOVERNOR" | grep "$SYSTEM_GOVERNOR" | wc -l)" -lt "1" ]; then
					PREV_SYSTEM_GOVERNOR=$(printf "%s $SYSTEM_GOVERNOR" "$PREV_SYSTEM_GOVERNOR");

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

					local pump_inc_step_at_min_freq_1_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_inc_step_at_min_freq_1";
					if [ ! -e $pump_inc_step_at_min_freq_1_tmp ]; then
						pump_inc_step_at_min_freq_1_tmp="/dev/null";
					fi;

					local pump_inc_step_at_min_freq_2_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_inc_step_at_min_freq_2";
					if [ ! -e $pump_inc_step_at_min_freq_2_tmp ]; then
						pump_inc_step_at_min_freq_2_tmp="/dev/null";
					fi;

					local pump_inc_step_at_min_freq_3_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_inc_step_at_min_freq_3";
					if [ ! -e $pump_inc_step_at_min_freq_3_tmp ]; then
						pump_inc_step_at_min_freq_3_tmp="/dev/null";
					fi;

					local pump_inc_step_at_min_freq_4_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_inc_step_at_min_freq_4";
					if [ ! -e $pump_inc_step_at_min_freq_4_tmp ]; then
						pump_inc_step_at_min_freq_4_tmp="/dev/null";
					fi;

					local pump_inc_step_1_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_inc_step_1";
					if [ ! -e $pump_inc_step_1_tmp ]; then
						pump_inc_step_1_tmp="/dev/null";
					fi;

					local pump_inc_step_2_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_inc_step_2";
					if [ ! -e $pump_inc_step_2_tmp ]; then
						pump_inc_step_2_tmp="/dev/null";
					fi;

					local pump_inc_step_3_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_inc_step_3";
					if [ ! -e $pump_inc_step_3_tmp ]; then
						pump_inc_step_3_tmp="/dev/null";
					fi;

					local pump_inc_step_4_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_inc_step_4";
					if [ ! -e $pump_inc_step_4_tmp ]; then
						pump_inc_step_4_tmp="/dev/null";
					fi;

					local pump_dec_step_at_min_freq_1_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_dec_step_at_min_freq_1";
					if [ ! -e $pump_dec_step_at_min_freq_1_tmp ]; then
						pump_dec_step_at_min_freq_1_tmp="/dev/null";
					fi;

					local pump_dec_step_at_min_freq_2_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_dec_step_at_min_freq_2";
					if [ ! -e $pump_dec_step_at_min_freq_2_tmp ]; then
						pump_dec_step_at_min_freq_2_tmp="/dev/null";
					fi;

					local pump_dec_step_at_min_freq_3_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_dec_step_at_min_freq_3";
					if [ ! -e $pump_dec_step_at_min_freq_3_tmp ]; then
						pump_dec_step_at_min_freq_3_tmp="/dev/null";
					fi;

					local pump_dec_step_at_min_freq_4_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_dec_step_at_min_freq_4";
					if [ ! -e $pump_dec_step_at_min_freq_4_tmp ]; then
						pump_dec_step_at_min_freq_4_tmp="/dev/null";
					fi;

					local pump_dec_step_1_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_dec_step_1";
					if [ ! -e $pump_dec_step_1_tmp ]; then
						pump_dec_step_1_tmp="/dev/null";
					fi;

					local pump_dec_step_2_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_dec_step_2";
					if [ ! -e $pump_dec_step_2_tmp ]; then
						pump_dec_step_2_tmp="/dev/null";
					fi;

					local pump_dec_step_3_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_dec_step_3";
					if [ ! -e $pump_dec_step_3_tmp ]; then
						pump_dec_step_3_tmp="/dev/null";
					fi;

					local pump_dec_step_4_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/pump_dec_step_4";
					if [ ! -e $pump_dec_step_4_tmp ]; then
						pump_dec_step_4_tmp="/dev/null";
					fi;

					local cpus_up_rate_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/cpus_up_rate";
					if [ ! -e $cpus_up_rate_tmp ]; then
						cpus_up_rate_tmp="/dev/null";
					fi;

					local cpus_down_rate_tmp="/sys/devices/system/cpu/cpufreq/$SYSTEM_GOVERNOR/cpus_down_rate";
					if [ ! -e $cpus_down_rate_tmp ]; then
						cpus_down_rate_tmp="/dev/null";
					fi;

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
					echo "$pump_inc_step_at_min_freq_1" > $pump_inc_step_at_min_freq_1_tmp;
					echo "$pump_inc_step_at_min_freq_2" > $pump_inc_step_at_min_freq_2_tmp;
					echo "$pump_inc_step_at_min_freq_3" > $pump_inc_step_at_min_freq_3_tmp;
					echo "$pump_inc_step_at_min_freq_4" > $pump_inc_step_at_min_freq_4_tmp;
					echo "$pump_inc_step_1" > $pump_inc_step_1_tmp;
					echo "$pump_inc_step_2" > $pump_inc_step_2_tmp;
					echo "$pump_inc_step_3" > $pump_inc_step_3_tmp;
					echo "$pump_inc_step_4" > $pump_inc_step_4_tmp;
					echo "$pump_dec_step_at_min_freq_1" > $pump_dec_step_at_min_freq_1_tmp;
					echo "$pump_dec_step_at_min_freq_2" > $pump_dec_step_at_min_freq_2_tmp;
					echo "$pump_dec_step_at_min_freq_3" > $pump_dec_step_at_min_freq_3_tmp;
					echo "$pump_dec_step_at_min_freq_4" > $pump_dec_step_at_min_freq_4_tmp;
					echo "$pump_dec_step_1" > $pump_dec_step_1_tmp;
					echo "$pump_dec_step_2" > $pump_dec_step_2_tmp;
					echo "$pump_dec_step_3" > $pump_dec_step_3_tmp;
					echo "$pump_dec_step_4" > $pump_dec_step_4_tmp;
					echo "$cpus_up_rate" > $cpus_up_rate_tmp;
					echo "$cpus_down_rate" > $cpus_down_rate_tmp;
				fi;
			done;

			#restore cpu hotplug parameters
			CPU_HOTPLUG_TWEAKS "tune";
		fi;

		log -p i -t "$FILE_NAME" "*** CPU_GOV_TWEAKS: $state ***: enabled";
	else
		return 0;
	fi;
}
# this needed for cpu tweaks apply from STweaks in real time
apply_cpu="$2";
if [ "$apply_cpu" == "update" ]; then
	CPU_GOV_TWEAKS "tune";
fi;

# mount sdcard and emmc, if usb mass storage is used
MOUNT_SD_CARD()
{
	if [ "$auto_mount_sd" == "on" ]; then
		if [ -e /dev/block/vold/179:32 ]; then
			echo "/dev/block/vold/179:32" > /sys/devices/virtual/android_usb/android0/f_mass_storage/lun0/file;
		fi;

		log -p i -t "$FILE_NAME" "*** MOUNT_SD_CARD ***";
	fi;
}
# run dual mount on boot
MOUNT_SD_CARD;

UKSM_CONTROL()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		echo "$uksm_gov_on" > /sys/kernel/mm/uksm/cpu_governor;
	elif [ "$state" == "sleep" ]; then
		echo "$uksm_gov_sleep" > /sys/kernel/mm/uksm/cpu_governor;
	fi;
	log -p i -t "$FILE_NAME" "*** UKSM_CONTROL $state ***: done";
}

WORKQUEUE_CONTROL()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		if [ "$power_efficient" == "on" ]; then
			echo "1" > /sys/module/workqueue/parameters/power_efficient;
		else
			echo "0" > /sys/module/workqueue/parameters/power_efficient;
		fi;
	elif [ "$state" == "sleep" ]; then
		echo "1" > /sys/module/workqueue/parameters/power_efficient;
	fi;
	log -p i -t "$FILE_NAME" "*** WORKQUEUE_CONTROL ***: done";
}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	# not on call, check if was powerd by USB on sleep, or didnt sleep at all
	if [ "$USB_POWER" -eq "0" ]; then
		WORKQUEUE_CONTROL "awake";
		UKSM_CONTROL "awake";
		echo "0" > /data/alu_cortex_sleep;
	else
		# Was powered by USB, and half sleep
		USB_POWER=0;

		log -p i -t "$FILE_NAME" "*** USB_POWER_WAKE: done ***";
	fi;
	# Didn't sleep, and was not powered by USB
	if [ "$auto_oom" == "on" ]; then
		sleep 1;
		$BB sh /res/uci.sh oom_config_screen_on $oom_config_screen_on;
	fi;
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	# we only read the config when the screen turns off ...
	PROFILE=$(cat "$DATA_DIR"/.active.profile);
	. "$DATA_DIR"/"$PROFILE".profile;

	CHARGING=$(cat /sys/class/power_supply/battery/batt_charging_source);

	# check if we powered by USB, if not sleep
	if [ "$CHARGING" -eq "1" ]; then
		WORKQUEUE_CONTROL "sleep";
		UKSM_CONTROL "sleep";
		echo "1" > /data/alu_cortex_sleep;
		log -p i -t "$FILE_NAME" "*** SLEEP mode ***";
	else
		# Powered by USB
		USB_POWER=1;
		echo "0" > /data/alu_cortex_sleep;
		log -p i -t "$FILE_NAME" "*** SLEEP mode: USB CABLE CONNECTED! No real sleep mode! ***";
	fi;
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
cortexbrain_background_process=1;

if [ "$cortexbrain_background_process" -eq "1" ] && [ "$(pgrep -f "/sbin/ext/cortexbrain-tune.sh" | wc -l)" -eq "2" ]; then
	(while true; do
		while [ "$(cat /sys/module/state_notifier/parameters/state_suspended)" != "N" ]; do
			sleep "3";
		done;
		# AWAKE State. all system ON
		AWAKE_MODE;

		while [ "$(cat /sys/module/state_notifier/parameters/state_suspended)" != "Y" ]; do
			sleep "3";
		done;
		# SLEEP state. All system to power save
		SLEEP_MODE;
	done &);
else
	if [ "$cortexbrain_background_process" -eq "0" ]; then
		echo "Cortex background disabled!"
	else
		echo "Cortex background process already running!";
	fi;
fi;
