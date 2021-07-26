#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
# exit with error status code if user is not root
if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root."
  exit 1
fi

# check for curl
CURLPATH="$(command -v curl)"
if [ -z "$CURLPATH" ]; then
  echo "* curl is being installed for this script to work"
  apt install -y curl
fi

# check for apt
APTPATH="$(command -v apt)"
if [ -z "$APTPATH" ]; then
  echo "* This script only works on ubuntu/debian"
  apt install -y curl
fi

# Check if used before
  if [ -d "/etc/pterodactyl" ]; then
    echo "Wings has already been installed on your system! You cannot run the script multiple times, it will fail!"
    exit 1
  fi

# Step One (Install docker)
echo "* Installing docker"
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
service docker start
systemctl enable --now docker

# Step Two (Installing wings)
echo "* Installing wings"
mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
chmod u+x /usr/local/bin/wings

# Step Three (Installing wings systemd)
echo "* Installing wings systemd"
systemctl enable --now wings
curl -o /etc/systemd/system/wings.service https://raw.githubusercontent.com/GalaxyGate/scripts/master/panels/pterodactyl/configs/wings.service

# Step Four (Leave instructions)
echo "* You will need to login to the panel and setup a node."
echo "* You can refer to this guide for help. (https://pterodactyl.io/wings/1.0/installing.html#configure)"
exit 1