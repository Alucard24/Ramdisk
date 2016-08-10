#!/sbin/bb/busybox sh
# Clear Cache script

(
	BB=/sbin/bb/busybox
	PROFILE=$($BB cat /data/.alucard/.active.profile);
	. /data/.alucard/${PROFILE}.profile;

	if [ "$cron_clear_app_cache" == "on" ]; then
		CACHE_JUNK=$($BB ls -d /data/data/*/cache)
		for i in $CACHE_JUNK; do
			$BB rm -rf $i/*
		done;

		# Old logs
		$BB rm -f /data/tombstones/*;
		$BB rm -f /data/anr/*;
		$BB rm -f /data/system/dropbox/*;
		date +%H:%M-%D > /data/crontab/cron-clear-file-cache;
		$BB echo "Done! Cleaned Apps Cache." >> /data/crontab/cron-clear-file-cache;
		$BB sync;
	fi;
)&
