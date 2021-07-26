#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
# Check if the user is root before proceeding
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
echo -e "Running script as root..."
# Update packages & Install needed packages
echo -e "Updating packages..."
apt update
echo "Installing curl, build-essentials, redis-server and git..."
apt install -y curl build-essential git redis-server
echo -e "Turning redis on..."
service redis-server start
systemctl enable redis-server
echo -e "Installing node..."
curl -sL https://deb.nodesource.com/setup_14.x | bash -
apt install -y nodejs
echo -e "Creating hastebin user"
sudo useradd -r -m -U -d /opt/hastebin -s /bin/bash hastebin
echo -e "Cloning hastebin repo..."
cd /opt/hastebin
git clone https://github.com/seejohnrun/haste-server
cp -R haste-server/* ./
rm -rf haste-server
echo -e "Adding config..."
curl -sSL https://raw.githubusercontent.com/GalaxyGate/scripts/master/pastebins/hastebin/config.js -o config.js
echo -e "Installing dependencies..."
npm install
curl -sSL https://raw.githubusercontent.com/GalaxyGate/scripts/master/pastebins/hastebin/install.sh -o /etc/systemd/system/hastebin.service
service hastebin start
systemctl enable hastebin
chown -R hastebin:hastebin /opt/hastebin
clear
mkdir -p /root/recipes
echo -e "Hastebin location: /opt/hastebin" >> /root/recipes/hastebin
echo -e "Hastebin Start Command: npm start OR node server.js" >> /root/recipes/hastebin
echo -e "service hastebin start or service hastebin restart to manage" >> /root/recipes/hastebin
echo -e "Installed hastebin server in /opt/haste-server"
clear