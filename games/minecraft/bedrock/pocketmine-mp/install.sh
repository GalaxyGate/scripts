#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
# Check if the user is root before proceeding
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
# Run on Ubuntu/Debian only
if ! [ -x "$(command -v apt)" ]; then
  echo "This script only works for Debian/Ubuntu users"
  exit 1
fi
# Update and install packages
echo "* Installing required packages"
apt update
apt install -y sudo screen unzip curl wget unzip
# Create user and directory
echo "* Creating minecraft user"
useradd -r -m -U -d /opt/minecraft -s /bin/bash minecraft
echo "* Creating folder for files"
runuser -l minecraft -c "mkdir pmmp"
# Check if dir is empty or not
if [ "$(ls -A /opt/minecraft/pmmp)" ]; then
     echo "Please empty the directory and re-run the script!"
     exit 1
fi
# Install server files
echo "* Downloading files"
runuser -l minecraft -c "cd pmmp && curl -sL https://get.pmmp.io | bash -s -"
runuser -l minecraft -c "cd pmmp && wget https://raw.githubusercontent.com/GalaxyGate/scripts/master/games/minecraft/bedrock/pocketmine-mp/server.properties"
runuser -l minecraft -c "cd pmmp && touch banned-ips.txt banned-players.txt ops.txt white-list.txt server.log"
runuser -l minecraft -c "cd pmmp && mkdir -p players worlds plugins resource_packs"
runuser -l minecraft -c "cd pmmp && chmod +x start.sh"
# Setup systemd
echo "* Setting up systemd service"
wget https://raw.githubusercontent.com/GalaxyGate/scripts/master/games/minecraft/bedrock/pocketmine-mp/minecraft_pmmp.service -O /etc/systemd/system/minecraft@pmmp.service
systemctl daemon-reload
systemctl start minecraft@pmmp.service
systemctl enable minecraft@pmmp.service
# Setup message
echo "* Leaving install message"
mkdir -p /root/recipes/minecraft
echo "SGVyZSBhcmUgc29tZSBjb21tYW5kcyB0aGF0IHdpbGwgaGVscCB5b3UgZWZmZWN0aXZlbHkgbWFuYWdlIHRoZSBzZXJ2ZXIuIAoKU3RhcnQgU2VydmVyOiAgc3lzdGVtY3RsIHN0YXJ0IG1pbmVjcmFmdEBwbW1wCgpSZXN0YXJ0IFNlcnZlcjogc3lzdGVtY3RsIHJlc3RhcnQgbWluZWNyYWZ0QHBtbXAKClN0YXR1cyBvZiBTZXJ2ZXI6IHN5c3RlbWN0bCBzdGF0dXMgbWluZWNyYWZ0QHBtbXAgCgpTdG9wIFNlcnZlcjogc3lzdGVtY3RsIHN0b3AgbWluZWNyYWZ0QHBtbXAKClZpZXcgbG9nczogY2F0IC9vcHQvbWluZWNyYWZ0L3BtbXAvc2VydmVyLmxvZyB8IHRhaWwgLW4gMzAKCkxvZ2luIHRvIHNlcnZlcjogc3UgLSBtaW5lY3JhZnQKClNlcnZlciBmaWxlczogL29wdC9taW5lY3JhZnQvcG1tcAo=" | base64 -d >> /root/recipes/minecraft/pocketmine-mp
clear