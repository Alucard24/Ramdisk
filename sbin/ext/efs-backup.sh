#!/sbin/bb/busybox sh

BB=/sbin/bb/busybox

if [ ! -f /data/.alucard/efsbackup.tar.gz ]; then
	$BB mkdir /data/.alucard;
	$BB chmod 777 /data/.alucard;
	$BB tar zcvf /data/.alucard/efsbackup.tar.gz /efs;
	$BB cat /dev/block/mmcblk0p1 > /data/.alucard/efsdev-mmcblk0p1.img;
	$BB gzip /data/.alucard/efsdev-mmcblk0p1.img;
	$BB cp /data/.alucard/efs* /data/media/;
	$BB chmod 777 /data/media/efsdev-mmcblk0p3.img;
	$BB chmod 777 /data/media/efsbackup.tar.gz;
	(
		$BB sleep 120;
		$BB cp /data/media/efs* /sdcard/;
	)&
fi;
