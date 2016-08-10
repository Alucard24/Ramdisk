#!/sbin/bb/busybox sh

(
	BB=/sbin/bb/busybox
	PROFILE=$($BB cat /data/.alucard/.active.profile);
	. /data/.alucard/${PROFILE}.profile;

	if [ "$cron_db_optimizing" == "on" ]; then
		for i in $($BB find /data -iname "*.db"); do
			/system/xbin/sqlite3 $i 'VACUUM;' > /dev/null;
			/system/xbin/sqlite3 $i 'REINDEX;' > /dev/null;
		done;

		date +%H:%M-%D > /data/crontab/cron-db-optimizing;
		$BB echo "Done! DB was successfully Optimized." >> /data/crontab/cron-db-optimizing;
		$BB sync;
	fi;
)&
