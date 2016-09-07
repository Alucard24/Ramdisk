#!/sbin/bb/busybox sh

BB=/sbin/bb/busybox

if [ ! -f /data/.b--b/efsbackup.tar.gz ]; then
	$BB mkdir /data/.b--b;
	$BB chmod 777 /data/.b--b;
	$BB tar zcvf /data/.b--b/efsbackup.tar.gz /efs;
	$BB cat /dev/block/mmcblk0p1 > /data/.b--b/efsdev-mmcblk0p1.img;
	$BB gzip /data/.b--b/efsdev-mmcblk0p1.img;
	$BB cp /data/.b--b/efs* /data/media/;
	$BB chmod 777 /data/media/efsdev-mmcblk0p3.img;
	$BB chmod 777 /data/media/efsbackup.tar.gz;
	(
		$BB sleep 120;
		$BB cp /data/media/efs* /sdcard/;
	)&
fi;
