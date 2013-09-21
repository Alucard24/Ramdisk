#!/sbin/busybox sh

mount -o remount,rw /
echo "0" > /tmp/early_wakeup;

(
	cat /sys/power/wait_for_fb_wake > /dev/null 2>&1;
	echo "1" > /tmp/early_wakeup;
)&
