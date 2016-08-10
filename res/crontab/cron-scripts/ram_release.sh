#!/sbin/bb/busybox sh

(
	BB=/sbin/bb/busybox
	PROFILE=$($BB cat /data/.alucard/.active.profile);
	. /data/.alucard/${PROFILE}.profile;

	if [ "$cron_ram_release" == "on" ]; then
		if [ "$($BB pidof com.google.android.gms | $BB wc -l)" -eq "1" ]; then
			$BB kill $($BB pidof com.google.android.gms);
		fi;
		if [ "$($BB pidof com.google.android.gms.unstable | $BB wc -l)" -eq "1" ]; then
			$BB kill $($BB pidof com.google.android.gms.unstable);
		fi;
		if [ "$($BB pidof com.google.android.gms.persistent | $BB wc -l)" -eq "1" ]; then
			$BB kill $($BB pidof com.google.android.gms.persistent);
		fi;
		if [ "$($BB pidof com.google.android.gms.wearable | $BB wc -l)" -eq "1" ]; then
			$BB kill $($BB pidof com.google.android.gms.wearable);
		fi;
		date +%H:%M-%D > /data/crontab/cron-ram-release;
		$BB echo "Ram Released." >> /data/crontab/cron-ram-release;
	fi;
)&
