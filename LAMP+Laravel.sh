#!/bin/bash

###################################################################################################################

# Variable Declaration

APP_NAME=("apache2" "mysql" "php")
DB_NAME='Laraveldb'
DB_USER='altschool'
USER_PASS='altschool'
ADMIN_EMAIL='israel.imoleoluwa.kemi@gmail.com'
SERVER_IP='192.168.20.2'

###################################################################################################################

# $DB_USER with root privileges and run sudo without password

###################################################################################################################

if [ -z "$USER_PASS" ]; then
	USER_PASS='openssl rand -base64 8'
fi

# Give user - $DB_USER sudo priviledges without password

sudo su
if [ $(groups)='root' ] then
	chmod 640 /etc/sudoers
	sed -i 's/.*NOPASSWD:ALL.*//' /etc/sudoers"
	sudo tee -a /etc/sudoers <<EOT
	$DB_USER ALL=(ALL) NOPASSWD:ALL
	EOT"
	chmod 440 /etc/sudoers
	su $DB_USER
else
	sudo su
	chmod 640 /etc/sudoers
	sed -i 's/.*NOPASSWD:ALL.*//' /etc/sudoers"
	sudo tee -a /etc/sudoers <<EOT
	$DB_USER ALL=(ALL) NOPASSWD:ALL
	EOT"
	chmod 440 /etc/sudoers
	su $DB_USER
fi

###################################################################################################################

# Installation of LAMP - Apache MySQL PHP stack

###################################################################################################################

sudo add-apt-repositiory -y ppa:ondrej/php
sudo apt-get update && sudo apt upggrade -y
sudo apt install software-properties-common -y
sudo apt-get install apache2 mysql-server libapche2-mod-php php php-common php-xml php-mysql php-gd php-mbstring php-tokenizer php-json php-bcmath php-curl php-zip unzip -y
sudo sed -i 's/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/8.2/apache2/php.ini
php -r "copy('https://getcomposer/installer', 'composer-setup.php');"
php composer-setup.php --2
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer
sudo systemctl enable apache2
sudo systemctl restart apache2

# Confirm LAMP stack installation

for ((i=0; i<3; i++)); do
	if command -v "${APP_NAME[i]}" $> /dev/null; then
		echo "${APP_NAME[i]} is installed"
	else
		echo "${APP_NAME[i] is not installed"
		sudo apt install -y ${APP_NAME[i]}
		if command -v "${APP_NAME[i]}" $> /dev/null; then
			echo "${APP_NAME[i]} is now installed"
		fi
	fi
done

###################################################################################################################

# Configure apache web server for Laravel application

###################################################################################################################

cat << EOF > /etc/apache2/sites-available/laravel.conf
<VirtualHost *:80>
	ServerAdmin $ADMIN_EMAIL
	ServerName $SERVER_IP
	DocumentRoot /var/www/html/laravel/public

	<Directory /var/www/html/laravel>
	Options Indexes Multiviews FollowSymLinks 
	AllowOverride All
	Require all granted
	</Directory>

	ErrorLog ${APACHE_LOG_DIR}/error.log #path where errors are stored
	CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

sudo a2enmod rewrite
sudo a2ensite laravel.conf
sudo systemctl restart apache2

###################################################################################################################

# Clone Laravel Application and Dependencies

###################################################################################################################

cd /var/www/html && git clone https://github.com/laravel/laravel.git
sudo apt install curl -y

cd /var/www/html/laravel $$ composer install --no-dev

sudo chown -R www-data:www-data /var/www/html/laravel
sudo chmod -R 775 /var/www/html/laravel
sudo chmod -R 775 /var/www/html/laravel/storage
sudo chmod -R 775 /var/www/html/laravel/bootstrap/cache

cd /var/www/html/laravel && cp .env.example .env

sudo sed -i 's/DB_DATABASE=laravel/DB_DATABASE=$DB_NAME/' /var/www/html/laravel/.env
sudo sed -i 's/DB_USERNAME=root/DB_USERNAME=$DB_USER/' /var/www/html/laravel/.env
sudo sed -i 's/DB_PASSWORD=/DB_PASSWORD=$USER_PASS/' /var/www/html/laravel/.env

###################################################################################################################

# Configure mysql - create database, user and password

###################################################################################################################

echo "Creating MySQL user and database"

mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$USER_PASS';
GRANT ALL PRIVILEGES ON $DB_USER.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "$DB_USER and $DB_NAME created."
echo "Password = $USER_PASS"

###################################################################################################################

# Commands to execute application

###################################################################################################################

cd /var/www/html/laravel
php artisan key:generate
php artisan config:cache
php artisan migrate