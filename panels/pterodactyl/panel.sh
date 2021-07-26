#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
if (( $# != 2 )); then
    echo "Please run the script like this ./panel.sh hostname.example.com admin@example.com"
    exit 1
fi
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
  if [ -d "/var/www/pterodactyl" ]; then
    echo "Pterodactyl has already been installed on your system! You cannot run the script multiple times, it will fail!"
    exit 1
  fi

# variables
hostname=$(hostname | sed "s/[^[:alnum:]]//g")
IP=$(curl -sS https://ipecho.net/plain)
WEBSERVER="nginx"

# Use command line arguements or default back to a galaxygate domain 
FQDN=$1
EMAIL=$2

# Check if defined or not
if [ -z "$FQDN" ]
then
      echo "* No FQDN was provided"
      exit 1
else
      FQDN=$1
fi

if [ -z "$EMAIL" ]
then
      echo "* No email was provided"
else
      EMAIL=$2
fi

# default MySQL credentials
MYSQL_USER="pterodactyl"
MYSQL_PASSWORD=$(date +%s | sha256sum | base64 | head -c 32)
PASSWORD=$(date +%s | sha256sum | base64 | head -c 16)

# download URLs
PANEL_DL_URL="https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz"

# Step One (Install dependencies)
echo "* Updating packages"
apt update -y && apt upgrade -y
echo "* Installing dependencies"
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
echo "* Adding php repository"
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
echo "* Adding mariadb repository"
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
add-apt-repository -y "deb [arch=amd64,arm64,ppc64el] http://mariadb.mirror.liquidtelecom.com/repo/10.4/ubuntu $(lsb_release -cs) main"
apt update -y
echo "* Installing php dependencies and basic tools"
apt -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
echo "* Enabling systemd for mariadb-server and redis-server"

# enable services
systemctl start mariadb
systemctl enable mariadb
systemctl start redis-server
systemctl enable redis-server

# Step two (Install composer)
echo "* Installing composer.."
export COMPOSER_ALLOW_SUPERUSER=1
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
echo "* Composer installed!"

# Step Three (Install panel)
echo "* Downloading pterodactyl panel files .. "
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl || exit
curl -Lo panel.tar.gz "$PANEL_DL_URL"
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
cp .env.example .env
cd /var/www/pterodactyl && composer install --no-dev --optimize-autoloader || exit
php artisan key:generate --force
echo "* Downloaded pterodactyl panel files & installed composer dependencies!"

# Step Four (Setup mariaDB)
echo "* Performing MySQL queries.."
echo "* Creating MySQL user.."
mysql -u root -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
echo "* Creating database.." 
mysql -u root -e "CREATE DATABASE panel;"
echo "* Grant privileges."
mysql -u root -e "GRANT ALL PRIVILEGES ON panel.* TO '${MYSQL_USER}'@'localhost' WITH GRANT OPTION;"
echo "* Flush privileges."
mysql -u root -e "FLUSH PRIVILEGES;"
echo "* MySQL database created & configured!"

# Step Five (Configure environment)
echo "* Configuring environment"
sed -i "s/DB_PASSWORD=/DB_PASSWORD=$MYSQL_PASSWORD/" .env
echo "APP_SERVICE_AUTHOR=$EMAIL" >> .env
echo "APP_URL=http://$FQDN" >> .env
echo "CACHE_DRIVER=redis" >> .env
echo "SESSION_DRIVER=redis" >> .env
echo "QUEUE_CONNECTION=redis" >> .env
echo "REDIS_HOST=localhost" >> .env
echo "REDIS_PASSWORD=null" >> .env
echo "REDIS_PORT=6379" >> .env
sed -i "s/MAIL_DRIVER=smtp/MAIL_DRIVER=mail/" .env
sed -i "s/no-reply@example\.com/$hostname@$IP/g" .env
sed -i "s/DB_HOST=127\.0\.0\.1/DB_HOST=localhost/" .env
php artisan migrate --seed --force --no-interaction

# Step Six (Make a user)
echo "* Creating admin user"
php artisan p:user:make --email "$EMAIL" --username=admin --name-first=admin --name-last=user --admin=1 --no-interaction --password="$PASSWORD"

# Step Seven (Change ownership of files to nginx)
chown -R www-data:www-data /var/www/pterodactyl/*

# Step Eight (Setting up crontabs)
echo "* Installing cronjob.. "
crontab -l | { cat; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1"; } | crontab -
echo "* Cronjob installed!"

# Step Nine (Setting up systemd)
echo "* Installing pteroq service.."
curl -o /etc/systemd/system/pteroq.service https://raw.githubusercontent.com/GalaxyGate/scripts/master/panels/pterodactyl/configs/pteroq.service 
systemctl enable pteroq.service
systemctl start pteroq

# Step Ten (Set up web server)
rm /etc/nginx/sites-enabled/default
curl -o /etc/nginx/sites-enabled/pterodactyl.conf https://raw.githubusercontent.com/GalaxyGate/scripts/master/panels/pterodactyl/configs/pterodactyl.conf
sed -i -e "s@<domain>@${FQDN}@g" /etc/nginx/sites-enabled/pterodactyl.conf
systemctl restart nginx

# Step 11 (Leave message)
echo "* Pterodactyl Panel successfully installed @ $FQDN"
echo "* "
echo "Pterodactyl Infomation" >> /root/pterodactyl_readme
echo "Pterodactyl Admin username: admin" >> /root/pterodactyl_readme
echo "Pterodactyl Admin Email: $EMAIL" >> /root/pterodactyl_readme
echo "Pterodactyl Admin Password: $PASSWORD" >> /root/pterodactyl_readme
echo "Pterodactyl Panel URL: http://$FQDN" >> /root/pterodactyl_readme
echo "MySQL details:" >> /root/pterodactyl_readme
echo "MySQL Username: $MYSQL_USER" >> /root/pterodactyl_readme
echo "MySQL Password: $MYSQL_PASSWORD" >> /root/pterodactyl_readme
echo "MySQL Database: panel:" >> /root/pterodactyl_readme
echo "Change values in /var/www/pterodactyl/.env & /etc/nginx/sites-enabled/pterodactyl.conf" >> /root/pterodactyl_readme
exit 1