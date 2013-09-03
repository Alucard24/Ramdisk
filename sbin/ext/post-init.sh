#!/sbin/busybox sh

BB=/sbin/busybox

$BB mount rootfs / -o remount,rw;

# some nice thing for dev
$BB ln -s /sys/devices/system/cpu/cpu0/cpufreq /cpufreq;
$BB ln -s /sys/devices/system/cpu/cpufreq/ /cpugov;

$BB mount rootfs / -o remount,ro
