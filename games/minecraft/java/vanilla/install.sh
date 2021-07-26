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
apt install -y sudo screen curl wget unzip
# Check for python
PYTHONPATH="$(command -v python)"
if [ -z "$PYTHONPATH" ]; then
  apt install -y python 
fi
# Define download links
MC_VERSION_URLS=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | python -c 'import json,sys,base64;obj=json.load(sys.stdin); print obj["versions"][0]["url"]') 
MC_LATEST_SNAPSHOT=$(curl -s $MC_VERSION_URLS | python -c 'import json,sys,base64;obj=json.load(sys.stdin); print obj["downloads"]["server"]["url"]')                         
# Create the minecraft account and directory for paper
echo "* Creating minecraft user"
useradd -r -m -U -d /opt/minecraft -s /bin/bash minecraft
echo "* Creating folder for files"
runuser -l minecraft -c "mkdir vanilla"
# Check if dir is empty or not
if [ "$(ls /opt/minecraft/vanilla/server.jar)" ]; then
     echo "Please empty the vanilla directory and re-run the script!"
     exit 1
fi
# Install java and the jar
echo "* Installing java and jar"
runuser -l minecraft -c "curl -sSL https://github.com/shyiko/jabba/raw/master/install.sh | bash && . ~/.jabba/jabba.sh"
runuser -l minecraft -c "jabba install openjdk@1.16.0"
runuser -l minecraft -c "jabba alias default openjdk@1.16.0"
runuser -l minecraft -c "cd vanilla && wget $MC_LATEST_SNAPSHOT -O server.jar"
# Auto accepts EULA only if commandline arg is presented
if [[ $EULA == "true" ]]
then
echo "* Accepting EULA"
runuser -l minecraft -c "cd vanilla && echo "#By changing the setting below to TRUE you are indicating your agreement to our EULA \(https://account.mojang.com/documents/minecraft_eula\)." >> eula.txt"
runuser -l minecraft -c "cd vanilla && echo "#$(date +"%a %b %d %T UTC %Y")" >> eula.txt"
runuser -l minecraft -c "cd vanilla && echo "eula=true" >> eula.txt"
fi
# Setup service
echo "* Setting up systemd service"
wget https://raw.githubusercontent.com/GalaxyGate/scripts/master/games/minecraft/java/vanilla/minecraft_vanilla.service -O /etc/systemd/system/minecraft@vanilla.service
systemctl start minecraft@vanilla.service
systemctl enable minecraft@vanilla.service
# Install message and clear
echo "* Leaving install message"
mkdir -p /root/recipes/minecraft
echo "SGVyZSBhcmUgc29tZSBjb21tYW5kcyB0aGF0IHdpbGwgaGVscCB5b3UgZWZmZWN0aXZlbHkgbWFuYWdlIHRoZSBzZXJ2ZXIuIAoKU3RhcnQgU2VydmVyOiAgc3lzdGVtY3RsIHN0YXJ0IG1pbmVjcmFmdEB2YW5pbGxhCgpSZXN0YXJ0IFNlcnZlcjogc3lzdGVtY3RsIHJlc3RhcnQgbWluZWNyYWZ0QHZhbmlsbGEKClN0YXR1cyBvZiBzZXJ2aWNlOiBzeXN0ZW1jdGwgc3RhdHVzIG1pbmVjcmFmdEB2YW5pbGxhCgpTdG9wIHNlcnZpY2U6IHN5c3RlbWN0bCBzdG9wIG1pbmVjcmFmdEB2YW5pbGxhCgpWaWV3IGxvZ3M6IGNhdCAvb3B0L21pbmVjcmFmdC92YW5pbGxhL2xvZ3MvbGF0ZXN0LmxvZyB8IHRhaWwgLW4gMzAKCkxvZ2luIHRvIHNlcnZlcjogc3UgLSBtaW5lY3JhZnQKClNlcnZlciBmaWxlczogL29wdC9taW5lY3JhZnQvdmFuaWxsYQoKU2VydmVyIGNvbmZpZzogL29wdC9taW5lY3JhZnQvdmFuaWxsYS9zZXJ2ZXIuY29uZgo=" | base64 -d >> /root/recipes/minecraft/vanilla
clear