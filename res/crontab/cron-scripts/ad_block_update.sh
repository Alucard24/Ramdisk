#!/sbin/bb/busybox sh

BB=/sbin/bb/busybox

PROFILE=$($BB cat /data/.alucard/.active.profile);
. /data/.alucard/${PROFILE}.profile;

if [ "$ad_block_update" == "on" ]; then

	TMPFILE=$($BB mktemp -t);
	HOST_FILE="/system/etc/hosts";

	if [ "$($BB mount | $BB grep rootfs | $BB cut -c 26-27 | $BB grep -c ro)" -eq "1" ]; then
		$BB mount -o remount,rw /;
	fi;
	if [ "$($BB mount | $BB grep system | $BB grep -c ro)" -eq "1" ]; then
		$BB mount -o remount,rw /system;
	fi;

	$BB echo "nameserver 8.8.8.8" > /system/etc/resolv.conf;
	$BB echo "nameserver 8.8.4.4" >> /system/etc/resolv.conf;

	TESTCONNECTION=$(/system/wget/wget http://www.google.com -O $TMPFILE > /dev/null 2>&1);
	if [ "$?" != "0" ]; then
		svc data enable;
		svc wifi enable;
		$BB sleep 10;
		DNS1=$(getprop net.dns1);
		DNS2=$(getprop net.rmnet0.dns1);
		DNS3=$(getprop net.rmnet0.dns2);
		$BB echo "nameserver $DNS1" >> /system/etc/resolv.conf;
		$BB echo "nameserver $DNS2" >> /system/etc/resolv.conf;
		$BB echo "nameserver $DNS3" >> /system/etc/resolv.conf;
		TESTCONNECTION=$(/system/wget/wget http://www.google.com -O $TMPFILE > /dev/null 2>&1);
		if [ "$?" != "0" ]; then
			date +%H:%M-%D > /data/crontab/cron-ad-block-update;
			$BB echo "Problem: no Internet connection!" >> /data/crontab/cron-ad-block-update;
			svc wifi disable;
		else
			/system/wget/wget http://winhelp2002.mvps.org/hosts.zip -O $TMPFILE > /dev/null 2>&1;
			$BB unzip -p $TMPFILE HOSTS > $HOST_FILE;
			$BB chmod 644 $HOST_FILE;
			svc wifi disable;
			date +%H:%M-%D > /data/crontab/cron-ad-block-update;
			$BB echo "AD Blocker: Updated." >> /data/crontab/cron-ad-block-update;
		fi;
	else
		/system/wget/wget http://winhelp2002.mvps.org/hosts.zip -O $TMPFILE > /dev/null 2>&1;
		$BB unzip -p $TMPFILE HOSTS > $HOST_FILE;
		$BB chmod 644 $HOST_FILE;
		date +%H:%M-%D > /data/crontab/cron-ad-block-update;
		$BB echo "AD Blocker: Updated." >> /data/crontab/cron-ad-block-update;
	fi;

	$BB rm -f $TMPFILE;

	$BB mount -o remount,ro /system;
fi;
