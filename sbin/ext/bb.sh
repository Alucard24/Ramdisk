#!/system/bin/sh

if [ "$(mount | grep rootfs | cut -c 26-27 | grep -c ro)" -eq "1" ]; then
	mount -o rw,remount -t rootfs /;
fi;

chmod 06755 /sbin/bb/busybox;
# Install latest busybox
/sbin/bb/busybox --install -s /sbin/bb/
