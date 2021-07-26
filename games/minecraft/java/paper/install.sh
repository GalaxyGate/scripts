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
apt install -y sudo screen unzip curl wget jq
# Grab latest build and version of paper
version=$(curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions' | jq -r '.[-1]')
build=$(curl -s "https://papermc.io/api/v2/projects/paper/versions/$version" | jq -r '.builds' | jq -r '.[-1]')
echo "* Creating minecraft user"
# Create the minecraft account and directory for paper
useradd -r -m -U -d /opt/minecraft -s /bin/bash minecraft
echo "* Creating folder for files"
runuser -l minecraft -c "mkdir paper"
# Check if dir is empty or not
if [ "$(ls -A /opt/minecraft/paper)" ]; then
     echo "Please empty the directory and re-run the script!"
     exit 1
fi
# Install java and the jar
echo "* Installing java & jar"
runuser -l minecraft -c "curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash && . ~/.jabba/jabba.sh"
runuser -l minecraft -c "jabba install openjdk@1.16.0"
runuser -l minecraft -c "jabba alias default openjdk@1.16.0"
runuser -l minecraft -c "cd paper && wget https://papermc.io/api/v2/projects/paper/versions/$version/builds/$build/downloads/paper-$version-$build.jar -O server.jar"
# Auto accepts EULA only if command line arg is presented
if [[ $EULA == "true" ]]
then
echo "* Accepting EULA"
runuser -l minecraft -c "cd paper && echo "#By changing the setting below to TRUE you are indicating your agreement to our EULA \(https://account.mojang.com/documents/minecraft_eula\)." >> eula.txt"
runuser -l minecraft -c "cd paper && echo "#$(date +"%a %b %d %T UTC %Y")" >> eula.txt"
runuser -l minecraft -c "cd paper && echo "eula=true" >> eula.txt"
fi
# Setup the service
echo "* Setting up systemd service"
wget https://raw.githubusercontent.com/GalaxyGate/scripts/master/games/minecraft/java/paper/minecraft_paper.service -O /etc/systemd/system/minecraft@paper.service
systemctl daemon-reload
systemctl start minecraft@paper.service
systemctl enable minecraft@paper.service
# Install message and clear
echo "* Leaving install message"
mkdir -p /root/recipes/minecraft
echo "SGVyZSBhcmUgc29tZSBjb21tYW5kcyB0aGF0IHdpbGwgaGVscCB5b3UgZWZmZWN0aXZlbHkgbWFuYWdlIHRoZSBzZXJ2ZXIuIAoKU3RhcnQgU2VydmVyOiAgc3lzdGVtY3RsIHN0YXJ0IG1pbmVjcmFmdEBwYXBlcgoKUmVzdGFydCBTZXJ2ZXI6IHN5c3RlbWN0bCByZXN0YXJ0IG1pbmVjcmFmdEBwYXBlcgoKU3RhdHVzIG9mIHNlcnZpY2U6IHN5c3RlbWN0bCBzdGF0dXMgbWluZWNyYWZ0QHBhcGVyIAoKU3RvcCBzZXJ2aWNlOiBzeXN0ZW1jdGwgc3RvcCBtaW5lY3JhZnRAcGFwZXIKClZpZXcgbG9nczogY2F0IC9vcHQvbWluZWNyYWZ0L3BhcGVyL2xvZ3MvbGF0ZXN0LmxvZyB8IHRhaWwgLW4gMzAKCkxvZ2luIHRvIHNlcnZlcjogc3UgLSBtaW5lY3JhZnQKClNlcnZlciBmaWxlczogL29wdC9taW5lY3JhZnQvcGFwZXIKClNlcnZlciBjb25maWc6IC9vcHQvbWluZWNyYWZ0L3BhcGVyL3NlcnZlci5jb25mCg==" | base64 -d >> /root/recipes/minecraft/paper
clear