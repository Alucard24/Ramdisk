#!/sbin/bb/busybox sh

(
	BB=/sbin/bb/busybox
	PROFILE=$($BB cat /data/.alucard/.active.profile);
	. /data/.alucard/${PROFILE}.profile;

	if [ "$cron_drop_cache" == "on" ]; then

		MEM_ALL=`$BB free | $BB grep Mem | $BB awk '{ print $2 }'`;
		MEM_USED=`$BB free | $BB grep Mem | $BB awk '{ print $3 }'`;
		MEM_USED_CALC=$(($MEM_USED*100/$MEM_ALL));

		# do clean cache only if cache uses 50% of free memory.
		if [ "$MEM_USED_CALC" -gt "50" ]; then
			$BB sync;
			$BB sleep 1;
			$BB sysctl -w vm.drop_caches=2;
			date +%H:%M-%D > /data/crontab/cron-clear-ram-cache;
			$BB echo "Cache is above 50%! Cleaned RAM Cache." >> /data/crontab/cron-clear-ram-cache;
		fi;
	fi;
)&
