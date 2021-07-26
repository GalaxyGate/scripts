#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
# Check if the user is root before proceeding
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
# Update packages and install deps
apt update
apt-get install software-properties-common dirmngr apt-transport-https curl -y
apt-key adv --fetch-keys http://repo.cubecoders.com/archive.key
apt-add-repository "deb http://repo.cubecoders.com/ debian/"
apt update
apt install ampinstmgr lib32gcc1 lib32stdc++6 lib32tinfo5 -y
# Define vars
AMP_SYS_USER=amp
AMP_ADS_PORT=8080
AMP_ADS_IP="0.0.0.0"
GETAMP_VERSION="1.6"
password=$(date +%s | sha256sum | base64 | head -c 32)
EXTERNAL_IP=$(wget -qO- https://ipecho.net/plain 2> /dev/null)
PROVISIONFLAGS="+Core.Webserver.UsingReverseProxy false"

echo
echo "GetAMP v$GETAMP_VERSION"
echo "AMP QuickStart installation script for Ubuntu 18.04+, Debian 8+ and CentOS 7+"
echo "This installer will perform the following:"
echo 
echo " * Install any pending system updates"
echo " * Install any prerequisites and dependencies via your systems package manager"
echo " * Add the CubeCoders repository to your system to keep AMP updated"
echo " * Install AMP and create a default management instance on port $AMP_ADS_PORT"
echo " * Configure the default AMP instance to start on boot"
echo
echo "External IP address : $EXTERNAL_IP"
echo "using useradd -d "/home/$AMP_SYS_USER -m $AMP_SYS_USER -s /bin/bash""
useradd -G tty -d /home/"$AMP_SYS_USER" -m "$AMP_SYS_USER" -s /bin/bash
su -l "$AMP_SYS_USER" -c "EXTERNAL_IP=$EXTERNAL_IP ampinstmgr quick admin $password $AMP_ADS_IP $AMP_ADS_PORT $PROVISIONFLAGS;exit $?" >> /root/installs/amp_logs
systemctl enable ampinstmgr.service
systemctl enable ampfirewall.service
systemctl enable ampfirewall.timer
systemctl enable amptasks.service
systemctl enable amptasks.timer
systemctl start ampfirewall.timer
systemctl start amptasks.timer
mkdir -p /root/recipes/panel
echo "Amp username: amp" >> /root/recipes/panel/amp
echo "Amp password: $password" >> /root/recipes/panel/amp
echo "Amp IP + Port: $EXTERNAL_IP:AMP_ADS_PORT" >> /root/recipes/panel/amp
echo "Amp wiki: https://github.com/cubecoders/amp/wiki" >> /root/recipes/panel/amp
echo "Note: You will have to provide your own license" >> /root/recipes/panel/amp
echo "Note: Licenses aren't refundable so purchase at your own risk" >> /root/recipes/panel/amp
clear
