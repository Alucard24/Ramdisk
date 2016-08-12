#!/sbin/bb/busybox sh

# Created By Dorimanx and Dairinin

BB=/sbin/bb/busybox

ROOTFS_MOUNT=$($BB mount | $BB grep rootfs | $BB cut -c26-27 | $BB grep -c rw)
if [ "$ROOTFS_MOUNT" -eq "0" ]; then
	$BB mount -o remount,rw /;
fi;

if [ "$($BB mount | $BB grep system | $BB grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /system;
fi;

if [ ! -e /data/crontab/ ]; then
	$BB mkdir /data/crontab/;
fi;

if [ ! -e /data/crontab/cron-scripts ]; then
	$BB mkdir /data/crontab/cron-scripts;
fi;

$BB cp -a /res/crontab/cron-scripts/* /data/crontab/cron-scripts;
$BB chown 0:0 /data/crontab/cron-scripts/*
$BB chmod 777 /data/crontab/cron-scripts/*

if [ ! -d /var/spool/cron/crontabs ]; then
	$BB mkdir -p /var/spool/cron/crontabs/;
fi;
$BB cp -a /res/crontab_service/cron-root /var/spool/cron/crontabs/root;
$BB chown 0:0 /var/spool/cron/crontabs/*;
$BB chmod 777 /var/spool/cron/crontabs/*;
# NOTE: all cron tasks set in /res/crontab_service/cron-root

# TZ list added by UpInTheAir@github big thanks!
# Check device local timezone & set for cron tasks
timezone=$(date +%z);
if [ "$timezone" == "+1400" ]; then
	TZ=UCT-14
elif [ "$timezone" == "+1300" ]; then
	TZ=UCT-13
elif [ "$timezone" == "+1245" ]; then
	TZ=CIST-12:45CIDT
elif [ "$timezone" == "+1200" ]; then
	TZ=NZST-12NZDT
elif [ "$timezone" == "+1100" ]; then
	TZ=UCT-11
elif [ "$timezone" == "+1030" ]; then
	TZ=LHT-10:30LHDT
elif [ "$timezone" == "+1000" ]; then
	TZ=UCT-10
elif [ "$timezone" == "+0930" ]; then
	TZ=UCT-9:30
elif [ "$timezone" == "+0900" ]; then
	TZ=UCT-9
elif [ "$timezone" == "+0830" ]; then
	TZ=KST
elif [ "$timezone" == "+0800" ]; then
	TZ=UCT-8
elif [ "$timezone" == "+0700" ]; then
	TZ=UCT-7
elif [ "$timezone" == "+0630" ]; then
	TZ=UCT-6:30
elif [ "$timezone" == "+0600" ]; then
	TZ=UCT-6
elif [ "$timezone" == "+0545" ]; then
	TZ=UCT-5:45
elif [ "$timezone" == "+0530" ]; then
	TZ=UCT-5:30
elif [ "$timezone" == "+0500" ]; then
	TZ=UCT-5
elif [ "$timezone" == "+0430" ]; then
	TZ=UCT-4:30
elif [ "$timezone" == "+0400" ]; then
	TZ=UCT-4
elif [ "$timezone" == "+0330" ]; then
	TZ=UCT-3:30
elif [ "$timezone" == "+0300" ]; then
	TZ=UCT-3
elif [ "$timezone" == "+0200" ]; then
	TZ=UCT-2
elif [ "$timezone" == "+0100" ]; then
	TZ=UCT-1
elif [ "$timezone" == "+0000" ]; then
	TZ=UCT
elif [ "$timezone" == "-0100" ]; then
	TZ=UCT1
elif [ "$timezone" == "-0200" ]; then
	TZ=UCT2
elif [ "$timezone" == "-0300" ]; then
	TZ=UCT3
elif [ "$timezone" == "-0330" ]; then
	TZ=NST3:30NDT
elif [ "$timezone" == "-0400" ]; then
	TZ=UCT4
elif [ "$timezone" == "-0430" ]; then
	TZ=UCT4:30
elif [ "$timezone" == "-0500" ]; then
	TZ=UCT5
elif [ "$timezone" == "-0600" ]; then
	TZ=UCT6
elif [ "$timezone" == "-0700" ]; then
	TZ=UCT7
elif [ "$timezone" == "-0800" ]; then
	TZ=UCT8
elif [ "$timezone" == "-0900" ]; then
	TZ=UCT9
elif [ "$timezone" == "-0930" ]; then
	TZ=UCT9:30
elif [ "$timezone" == "-1000" ]; then
	TZ=UCT10
elif [ "$timezone" == "-1100" ]; then
	TZ=UCT11
elif [ "$timezone" == "-1200" ]; then
	TZ=UCT12
else
	TZ=UCT
fi;

# set cron timezone
export TZ

# use /var/spool/cron/crontabs/ call the crontab file "root"
if [ "$($BB pidof crond | $BB wc -l)" -eq "0" ]; then
	$BB nohup /sbin/bb/crond -c /var/spool/cron/crontabs/ > /data/.alucard/cron.txt &
	$BB sleep 1;
	PIDOFCRON=$($BB pidof crond);
	if [ -f /system/xbin/su ]; then
		su -c echo "-900" > /proc/"$PIDOFCRON"/oom_score_adj;
	fi;
fi;

$BB mount -o remount,ro /system;

