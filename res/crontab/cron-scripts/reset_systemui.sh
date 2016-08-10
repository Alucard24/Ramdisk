#!/sbin/bb/busybox sh

BB=/sbin/bb/busybox
PROFILE=$($BB cat /data/.alucard/.active.profile);
. /data/.alucard/${PROFILE}.profile;

if [ "$cron_reset_systemui" == "on" ]; then
	$BB pkill -f com.android.systemui
	date +%H:%M-%D > /data/crontab/cron-reset-systemui;
	$BB echo "SystemUI Drain Terminated." >> /data/crontab/cron-reset-systemui;
fi;
