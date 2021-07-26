#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
# Exit if non-root user is running this script
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi
# Run on Ubuntu/Debian only
if ! [ -x "$(command -v apt)" ]; then
  echo "This script only works for Debian/Ubuntu users"
  exit 1
fi
# Install packages
echo "* Installing required packages"
apt-get update
apt-get install -y sudo screen curl wget unzip jq
# Creating User
echo "* Creating user"
useradd -r -m -U -d /opt/terraria -s /bin/bash terraria
# Check if dir is empty or not
echo "* Creating folder"
runuser -l terraria -c "mkdir pc"
if [ "$(ls /opt/terraria/pc/)" ]; then
     echo "Please empty the /opt/terraria/pc folder and re-run the script!"
     exit 1
fi
# Setting variables
VER=$(curl -sSL https://terraria.org/api/get/dedicated-servers-names | jq -r '.[0]')
DOWNLOAD_LINK="https://terraria.org/api/download/pc-dedicated-server/$VER"
CLEAN_VERSION=$(echo "${DOWNLOAD_LINK##*/}" | cut -d'-' -f3 | cut -d'.' -f1)
# Validate download URL
echo "* Checking if download link is valid"
if [ ! -z "${DOWNLOAD_URL}" ]; then
    if curl --output /dev/null --silent --head --fail "${DOWNLOAD_URL}"; then
        echo -e "* Download link is valid"
        DOWNLOAD_LINK="${DOWNLOAD_URL}"
    else
        echo -e "* Download link is invalid"
        exit 2
    fi
fi
# Download the files and unzip
echo "* Downloading files"
cd /opt/terraria/pc
curl -sSL "${DOWNLOAD_LINK}" -o "${DOWNLOAD_LINK##*/}"
echo "* Unzipping files"
unzip "${DOWNLOAD_LINK##*/}"
# Copy linux files over
echo "* Coppying files over"
cp -R "${CLEAN_VERSION}"/Linux/* ./
chmod +x TerrariaServer.bin.x86_64
# Delete old files
echo "* Cleaning unused files"
rm -rf "${CLEAN_VERSION}"
rm -rf "${DOWNLOAD_LINK##*/}"
# Set Permissions
echo "* Setting permissions"
chown -R terraria:terraria /opt/terraria
# Make install folder and make message
echo "* Leaving install message"
mkdir -p /root/recipes/terraria
echo "LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tClVzZXI6IHRlcnJhcmlhCkRpcmVjdG9yeTogL29wdC90ZXJyYXJpYS9wYwpXb3JsZCBTYXZlczogL29wdC90ZXJyYXJpYS8ubG9jYWwvc2hhcmUvVGVycmFyaWEvV29ybGRzCkNvbW1hbmQ6IC9vcHQvdGVycmFyaWEvcGMvVGVycmFyaWFTZXJ2ZXIuYmluLng4Nl82NApIb3cgdG8gbG9naW46IHN1IC0gdGVycmFyaWEKLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCg==" | base64 --decode >> /root/recipes/terraria/pc
clear