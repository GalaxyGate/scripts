#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
# Check if the user is root before proceeding
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
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
# Grab latest bedrock version
echo "* Looking for latest minecraft download"
curl -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.1317.212 Safari/537.36" -H "Accept-Language: en" -H "Accept-Encoding: gzip, deflate" -o versions.html.gz https://www.minecraft.net/en-us/download/server/bedrock 
DOWNLOAD_URL=$(zgrep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*' versions.html.gz)
# Create user and directory
echo "* Creating minecraft user"
useradd -r -m -U -d /opt/minecraft -s /bin/bash minecraft
echo "* Creating folder for files"
runuser -l minecraft -c "mkdir bedrock"
# Check if dir is empty or not
if [ "$(ls -A /opt/minecraft/bedrock)" ]; then
     echo "Please empty the directory and re-run the script!"
     exit 1
fi
# Download the server files and unzip files
echo "* Downloading files"
runuser -l minecraft -c "cd bedrock && wget $DOWNLOAD_URL -O server.zip"
runuser -l minecraft -c "cd bedrock && unzip -q server.zip"
runuser -l minecraft -c "cd bedrock && rm server.zip"
runuser -l minecraft -c "cd bedrock && wget https://raw.githubusercontent.com/GalaxyGate/scripts/master/games/minecraft/bedrock/dedicated/start.sh -O start.sh && chmod +x start.sh"
# Setup service
echo "* Setting up systemd service"
wget https://raw.githubusercontent.com/GalaxyGate/scripts/master/games/minecraft/bedrock/dedicated/minecraft_bedrock.service -O /etc/systemd/system/minecraft@bedrock.service
systemctl daemon-reload
systemctl start minecraft@bedrock.service
systemctl enable minecraft@bedrock.service
# Install message and clear
mkdir -p /root/recipes/minecraft/
echo "* Leaving install message"
echo "SGVyZSBhcmUgc29tZSBjb21tYW5kcyB0aGF0IHdpbGwgaGVscCB5b3UgZWZmZWN0aXZlbHkgbWFuYWdlIHRoZSBzZXJ2ZXIuIAoKU3RhcnQgU2VydmVyOiAgc3lzdGVtY3RsIHN0YXJ0IG1pbmVjcmFmdEBiZWRyb2NrCgpSZXN0YXJ0IFNlcnZlcjogc3lzdGVtY3RsIHJlc3RhcnQgbWluZWNyYWZ0QGJlZHJvY2sKClN0b3AgU2VydmVyOiBzeXN0ZW1jdGwgc3RvcCBtaW5lY3JhZnRAYmVkcm9jawoKU3RhdHVzIG9mIFNlcnZlcjogc3lzdGVtY3RsIHN0YXR1cyBtaW5lY3JhZnRAYmVkcm9jawo=" | base64 -d >> /root/recipes/minecraft/bedrock
clear