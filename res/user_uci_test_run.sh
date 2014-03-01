#!/sbin/busybox sh
# universal configurator interface for user/dev/ testing.
# by Gokhan Moral and Voku and Dorimanx and Alucard24

# stop uci.sh from running all the PUSH Buttons in stweaks on boot
mount -o remount,rw rootfs;
chown -R 0.1000 /res/customconfig/actions/;
chmod -R 6755 /res/customconfig/actions/;
mv /res/customconfig/actions/push-actions/* /res/no-push-on-boot/;
chmod 6755 /res/no-push-on-boot/*;

UCI_PID=`pgrep "uci.sh"`;
renice -n 15 -p $UCI_PID;

# apply STweaks settings
pkill -f "com.gokhanmoral.stweaks.app";

ACTION_SCRIPTS=/res/customconfig/actions;
source /res/customconfig/customconfig-helper;

# first, read defaults
read_defaults;

# read the config from the active profile
read_config;

apply_config;
write_config;

# restore all the PUSH Button Actions back to there location
mount -o remount,rw rootfs;
mv /res/no-push-on-boot/* /res/customconfig/actions/push-actions/;
pkill -f "com.gokhanmoral.stweaks.app";

