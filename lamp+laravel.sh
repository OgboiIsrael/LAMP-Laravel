#!/bin/bash

# Set variables
APP_DIR="/var/www/laravel-app"  # Change this to your desired app directory
GIT_REPO="https://github.com/laravel/laravel.git"
DB_NAME="laravel_db"
DB_USER="laravel_user"
DB_PASS="your_password"

# Update the system and install necessary packages
sudo apt update
sudo apt install -y git apache2 php mysql-server php-mysql composer

# Clone the Laravel repository
git clone $GIT_REPO $APP_DIR

# Configure Laravel application
cd $APP_DIR
cp .env.example .env

# Generate application key
php artisan key:generate

# Install Composer dependencies
composer install

# Create the database
mysql -u root -p -e "CREATE DATABASE $DB_NAME;"
mysql -u root -p -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -u root -p -e "FLUSH PRIVILEGES;"

# Set up Apache virtual host
cat <<EOL | sudo tee /etc/apache2/sites-available/laravel.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot $APP_DIR/public
    ServerName your_domain.com

    <Directory $APP_DIR/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

# Enable the virtual host and restart Apache
sudo a2ensite laravel.conf
sudo systemctl restart apache2

# Set proper permissions
sudo chown -R www-data:www-data $APP_DIR
sudo chmod -R 755 $APP_DIR/storage

# Restart Apache
sudo systemctl restart apache2

# Display success message
echo "Laravel application is installed and configured. Open your browser to access it."