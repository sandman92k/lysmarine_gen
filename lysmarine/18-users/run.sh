#!/bin/bash -e
apt-get -y -q install sudo policykit-1

## Set root password
echo 'root:changeme' | chpasswd

## Roemove default uder (if any)
oldUser=$(cat /etc/passwd | grep 1000:1000 | cut -f1 -d:) 
if [[ ! -z $oldUser ]]; then 
	echo "Removing user "$oldUser
	userdel -r -f $oldUser
else
	echo "No default user found !"
fi

## Add default user
adduser --uid 1000 --home /home/user --quiet --disabled-password -gecos "lysmarine" user
echo 'user:changeme' | chpasswd
echo "user ALL=(ALL:ALL) ALL" >> /etc/sudoers
usermod -a -G netdev user
usermod -a -G tty user
usermod -a -G sudo user

## Create signalk user to run the server.
if [ ! -d /home/signalk ] ; then
	echo "Creating signalk user"
	adduser --home /home/signalk --gecos --system --disabled-password --disabled-login signalk
fi

## Create pypilot user to run the services.
if [ ! -d /home/pypilot ] ; then
	echo "Creating pypilot user"
	adduser --home /home/pypilot --gecos --system --disabled-password --disabled-login pypilot
fi


## Manage the permissions and privileges.
if [[ -d /etc/polkit-1 ]]; then
	echo "polkit found, adding rules"
	install -v $FILE_FOLDER/all_all_users_to_shutdown_reboot.pkla "/etc/polkit-1/localauthority/50-local.d/"
	install -d "/etc/polkit-1/localauthority/10-vendor.d"
	install -v $FILE_FOLDER/org.freedesktop.NetworkManager.pkla  "/etc/polkit-1/localauthority/10-vendor.d/"
fi

if [[ -f /etc/sudoers.d/010_pi-nopasswd ]]; then # remove the raspbian no-pwd sudo to user pi.
	rm /etc/sudoers.d/010_pi-nopasswd
fi

echo 'PATH="/sbin:/usr/sbin:$PATH"' >> /home/user/.profile # Give user capability to halt and reboot.

if [ -f /root/.not_logged_in_yet ] ;then # Disable Armbian first login script.
	rm /root/.not_logged_in_yet
fi

## Prevent the creation of useless home folders on first boot.
sed -i 's/^DESKTOP=/#&/'     /etc/xdg/user-dirs.defaults; 
sed -i 's/^TEMPLATES=/#&/'   /etc/xdg/user-dirs.defaults; 
sed -i 's/^PUBLICSHARE=/#&/' /etc/xdg/user-dirs.defaults; 
sed -i 's/^MUSIC=/#&/'       /etc/xdg/user-dirs.defaults; 
sed -i 's/^PICTURES=/#&/'    /etc/xdg/user-dirs.defaults; 
sed -i 's/^VIDEOS=/#&/'      /etc/xdg/user-dirs.defaults; 