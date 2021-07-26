#!/bin/bash
# exit with error status code if user is not root
if [[ $EUID -ne 0 ]]; then
  echo "* This script must be executed with root."
  exit 1
fi
# Check for curl
CURLPATH="$(command -v curl)"
if [ -z "$CURLPATH" ]; then
  echo "* curl is being installed for this script to work"
  apt install -y curl
fi
curl --silent -o panel.sh "https://raw.githubusercontent.com/GalaxyGate/scripts/master/panels/pterodactyl/panel.sh"
curl --silent -o wings.sh "https://raw.githubusercontent.com/GalaxyGate/scripts/master/panels/pterodactyl/wings.sh"
chmod +x panel.sh
chmod +x wings.sh
echo "* ./panel.sh <hostname> <email>"
echo "* ./wings.sh"