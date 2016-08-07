#!/sbin/bb/busybox sh
# universal configurator interface for user/dev/ testing.
# by Gokhan Moral and Voku and Dorimanx and Alucard24

# stop uci.sh from running all the PUSH Buttons in stweaks on boot
BB=/sbin/bb/busybox

if [ "$($BB mount | $BB grep rootfs | $BB cut -c 26-27 | $BB grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /;
fi;
if [ "$($BB mount | $BB grep system | $BB grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /system;
fi;

$BB chown -R root:system /res/customconfig/actions/;
$BB chmod -R 06755 /res/customconfig/actions/;
$BB mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;
$BB chmod 06755 /res/no-push-on-boot/*;
$BB cp /res/misc_scripts/config_backup_restore /res/customconfig/actions/push-actions/;
$BB chmod 06755 /res/customconfig/actions/push-actions/config_backup_restore;

ACTION_SCRIPTS=/res/customconfig/actions;
source /res/customconfig/customconfig-helper;

# first, read defaults
read_defaults;

# read the config from the active profile
read_config;
apply_config;
write_config;

# restore all the PUSH Button Actions back to there location
$BB mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
$BB pkill -f "com.gokhanmoral.stweaks.app";

$BB mount -o remount,ro /system;

