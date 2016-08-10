#!/sbin/bb/busybox sh
# memory process reclaim script, made by Dorimanx

(
	BB=/sbin/bb/busybox
	PROFILE=$($BB cat /data/.alucard/.active.profile);
	. /data/.alucard/${PROFILE}.profile;

	if [ ! -f /system/xbin/su ]; then
		exit 1;
	fi;

	if [ "$cron_process_reclaim" == "on" ]; then
		for i in $($BB ls /proc/ | $BB grep -E '^[0-9]+'); do
			if [ "$i" -ge "1500" ] && [ -f /proc/$i/reclaim ]; then
				su -c echo "all" > /proc/$i/reclaim;
			fi;
		done;
		date +%H:%M-%D > /data/crontab/cron-mem-process-reclaim;
		$BB echo "Done! Ram Reclaimed." >> /data/crontab/cron-mem-process-reclaim;
	fi;
)&
