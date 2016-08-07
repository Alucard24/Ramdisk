#!/sbin/bb/busybox sh

BB=/sbin/bb/busybox

input keyevent 26
$BB sync
$BB sync
stop
$BB mount -o remount,ro /system;
$BB echo "rebooting to recovery now"
$BB sleep 3;
reboot recovery

