#!/system/bin/sh
# Copyright (c) 2009-2012, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

target=`getprop ro.board.platform`

case "$target" in
    "msm8960")
         echo 1 > /sys/module/rpm_resources/enable_low_power/L2_cache
         echo 1 > /sys/module/rpm_resources/enable_low_power/pxo
         echo 1 > /sys/module/rpm_resources/enable_low_power/vdd_dig
         echo 1 > /sys/module/rpm_resources/enable_low_power/vdd_mem
         echo 1 > /sys/module/pm_8x60/modes/cpu0/retention/idle_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu1/retention/idle_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu2/retention/idle_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu3/retention/idle_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu0/power_collapse/suspend_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu1/power_collapse/suspend_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu2/power_collapse/suspend_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu3/power_collapse/suspend_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu0/standalone_power_collapse/suspend_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu1/standalone_power_collapse/suspend_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu2/standalone_power_collapse/suspend_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu3/standalone_power_collapse/suspend_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu0/standalone_power_collapse/idle_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu1/standalone_power_collapse/idle_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu2/standalone_power_collapse/idle_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu3/standalone_power_collapse/idle_enabled
         echo 1 > /sys/module/pm_8x60/modes/cpu0/power_collapse/idle_enabled
         echo 1 > /sys/devices/system/cpu/cpu1/online
         echo 1 > /sys/devices/system/cpu/cpu2/online
         echo 1 > /sys/devices/system/cpu/cpu3/online
         # set DCVS parameters for CPU
         echo 40000 > /sys/module/msm_dcvs/cores/cpu0/slack_time_max_us
         echo 40000 > /sys/module/msm_dcvs/cores/cpu0/slack_time_min_us
         echo 100000 > /sys/module/msm_dcvs/cores/cpu0/em_win_size_min_us
         echo 500000 > /sys/module/msm_dcvs/cores/cpu0/em_win_size_max_us
         echo 0 > /sys/module/msm_dcvs/cores/cpu0/slack_mode_dynamic
         echo 1000000 > /sys/module/msm_dcvs/cores/cpu0/disable_pc_threshold
         echo 25000 > /sys/module/msm_dcvs/cores/cpu1/slack_time_max_us
         echo 25000 > /sys/module/msm_dcvs/cores/cpu1/slack_time_min_us
         echo 100000 > /sys/module/msm_dcvs/cores/cpu1/em_win_size_min_us
         echo 500000 > /sys/module/msm_dcvs/cores/cpu1/em_win_size_max_us
         echo 0 > /sys/module/msm_dcvs/cores/cpu1/slack_mode_dynamic
         echo 1000000 > /sys/module/msm_dcvs/cores/cpu1/disable_pc_threshold
         echo 25000 > /sys/module/msm_dcvs/cores/cpu2/slack_time_max_us
         echo 25000 > /sys/module/msm_dcvs/cores/cpu2/slack_time_min_us
         echo 100000 > /sys/module/msm_dcvs/cores/cpu2/em_win_size_min_us
         echo 500000 > /sys/module/msm_dcvs/cores/cpu2/em_win_size_max_us
         echo 0 > /sys/module/msm_dcvs/cores/cpu2/slack_mode_dynamic
         echo 1000000 > /sys/module/msm_dcvs/cores/cpu2/disable_pc_threshold
         echo 25000 > /sys/module/msm_dcvs/cores/cpu3/slack_time_max_us
         echo 25000 > /sys/module/msm_dcvs/cores/cpu3/slack_time_min_us
         echo 100000 > /sys/module/msm_dcvs/cores/cpu3/em_win_size_min_us
         echo 500000 > /sys/module/msm_dcvs/cores/cpu3/em_win_size_max_us
         echo 0 > /sys/module/msm_dcvs/cores/cpu3/slack_mode_dynamic
         echo 1000000 > /sys/module/msm_dcvs/cores/cpu3/disable_pc_threshold
         # set DCVS parameters for GPU
         echo 20000 > /sys/module/msm_dcvs/cores/gpu0/slack_time_max_us
         echo 20000 > /sys/module/msm_dcvs/cores/gpu0/slack_time_min_us
         echo 0 > /sys/module/msm_dcvs/cores/gpu0/slack_mode_dynamic
         # set msm_mpdecision parameters
         echo 45000 > /sys/module/msm_mpdecision/slack_time_max_us
         echo 15000 > /sys/module/msm_mpdecision/slack_time_min_us
         echo 100000 > /sys/module/msm_mpdecision/em_win_size_min_us
         echo 1000000 > /sys/module/msm_mpdecision/em_win_size_max_us
         echo 3 > /sys/module/msm_mpdecision/online_util_pct_min
         echo 25 > /sys/module/msm_mpdecision/online_util_pct_max
         echo 97 > /sys/module/msm_mpdecision/em_max_util_pct
         echo 2 > /sys/module/msm_mpdecision/rq_avg_poll_ms
         echo 10 > /sys/module/msm_mpdecision/mp_em_rounding_point_min
         echo 85 > /sys/module/msm_mpdecision/mp_em_rounding_point_max
         echo 50 > /sys/module/msm_mpdecision/iowait_threshold_pct
         #set permissions for SSRM
         chown radio.system /sys/power/cpufreq_max_limit
         chown radio.system /sys/power/cpufreq_min_limit
         chown radio.system /sys/power/cpufreq_table
         chown radio.system /sys/devices/system/cpu/kernel_max
         chown radio.system /sys/class/power_supply/battery/siop_level
         chown radio.system /sys/class/lcd/panel/siop_enable
         chmod 664 /sys/power/cpufreq_max_limit
         chmod 664 /sys/power/cpufreq_min_limit
         chmod 664 /sys/power/cpufreq_table
         chmod 664 /sys/devices/system/cpu/kernel_max
         #set permissions for the nodes needed by display on/off hook
         chown -h system /sys/module/msm_dcvs/cores/cpu0/slack_time_max_us
         chown -h system /sys/module/msm_dcvs/cores/cpu0/slack_time_min_us
         chown -h system /sys/module/msm_mpdecision/slack_time_max_us
         chown -h system /sys/module/msm_mpdecision/slack_time_min_us
         chmod -h 664 /sys/module/msm_dcvs/cores/cpu0/slack_time_max_us
         chmod -h 664 /sys/module/msm_dcvs/cores/cpu0/slack_time_min_us
         chmod -h 664 /sys/module/msm_mpdecision/slack_time_max_us
         chmod -h 664 /sys/module/msm_mpdecision/slack_time_min_us
         soc_id=`cat /sys/devices/system/soc/soc0/id`
         case "$soc_id" in
             "130")
                 echo 230 > /sys/class/gpio/export
                 echo 228 > /sys/class/gpio/export
                 echo 229 > /sys/class/gpio/export
                 echo "in" > /sys/class/gpio/gpio230/direction
                 echo "rising" > /sys/class/gpio/gpio230/edge
                 echo "in" > /sys/class/gpio/gpio228/direction
                 echo "rising" > /sys/class/gpio/gpio228/edge
                 echo "in" > /sys/class/gpio/gpio229/direction
                 echo "rising" > /sys/class/gpio/gpio229/edge
                 echo 253 > /sys/class/gpio/export
                 echo 254 > /sys/class/gpio/export
                 echo 257 > /sys/class/gpio/export
                 echo 258 > /sys/class/gpio/export
                 echo 259 > /sys/class/gpio/export
                 echo "out" > /sys/class/gpio/gpio253/direction
                 echo "out" > /sys/class/gpio/gpio254/direction
                 echo "out" > /sys/class/gpio/gpio257/direction
                 echo "out" > /sys/class/gpio/gpio258/direction
                 echo "out" > /sys/class/gpio/gpio259/direction
                 chown -h media /sys/class/gpio/gpio253/value
                 chown -h media /sys/class/gpio/gpio254/value
                 chown -h media /sys/class/gpio/gpio257/value
                 chown -h media /sys/class/gpio/gpio258/value
                 chown -h media /sys/class/gpio/gpio259/value
                 chown -h media /sys/class/gpio/gpio253/direction
                 chown -h media /sys/class/gpio/gpio254/direction
                 chown -h media /sys/class/gpio/gpio257/direction
                 chown -h media /sys/class/gpio/gpio258/direction
                 chown -h media /sys/class/gpio/gpio259/direction
                 echo 0 > /sys/module/rpm_resources/enable_low_power/vdd_dig
                 echo 0 > /sys/module/rpm_resources/enable_low_power/vdd_mem
                 ;;
         esac
         ;;
esac

emmc_boot=`getprop ro.boot.emmc`
case "$emmc_boot"
    in "true")
        chown -h system /sys/devices/platform/rs300000a7.65536/force_sync
        chown -h system /sys/devices/platform/rs300000a7.65536/sync_sts
        chown -h system /sys/devices/platform/rs300100a7.65536/force_sync
        chown -h system /sys/devices/platform/rs300100a7.65536/sync_sts
    ;;
esac

case "$target" in
    "msm8960" | "msm8660" | "msm7630_surf")
        echo 10 > /sys/devices/platform/msm_sdcc.3/idle_timeout
        ;;
esac

# Post-setup services
case "$target" in
    "msm8960")
        soc_id=`cat /sys/devices/system/soc/soc0/id`
        case "$soc_id" in
             "153") #8064 v2
                 start thermal-engine
             ;;

	     *) #all targets except 8064 v2
		 start thermald
	     ;;
        esac
    ;;
esac
case "$target" in
    "msm8660" | "msm8960" | "msm8974")
        start mpdecision
    ;;
esac

# Install AdrenoTest.apk if not already installed
if [ -f /data/prebuilt/AdrenoTest.apk ]; then
    if [ ! -d /data/data/com.qualcomm.adrenotest ]; then
        pm install /data/prebuilt/AdrenoTest.apk
    fi
fi

#fastrpc permission setting
insmod /system/lib/modules/adsprpc.ko
chown -h system.system /dev/adsprpc-smd
chmod -h 666 /dev/adsprpc-smd
