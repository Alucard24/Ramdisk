#!/sbin/busybox sh

stop
sync
sync
/sbin/busybox mount -o remount,ro /system;
echo "rebooting to recovery now"
sleep 2;
reboot recovery

