#!/bin/bash -xe

# STEP 1 - Set Variables
DBName='YOUR_DB_NAME_HERE'
DBRootPassword='YOUR_DB_ROOT_PASSWORD_HERE'

DBUser='YOUR_DB_USER_HERE'
DBPassword='YOUR_DB_PASSWORD_HERE'

RDSDNSName='YOUR_RDS_DNS_NAME_HERE'
RDSUserName='YOUR_RDS_USERNAME_HERE'
RDSDBName='YOUR_RDS_DB_NAME_HERE'

# STEP 2 - Install System Software - including Web and DB Servers
dnf install wget php-mysqlnd httpd php-fpm php-mysqli mariadb105-server php-json php php-devel -y

# STEP 3 - Start and Enable Web and DB Servers
systemctl enable httpd
systemctl start httpd
systemctl start mariadb

# STEP 4 - Set Mariadb Root Password
mysqladmin -u root password $DBRootPassword

# STEP 5 - Install Wordpress
wget http://wordpress.org/latest.tar.gz -P /var/www/html
cd /var/www/html
tar -zxvf latest.tar.gz
cp -rvf wordpress/* .
rm -R wordpress
rm latest.tar.gz

# STEP 6 - Configure Wordpress
cp ./wp-config-sample.php ./wp-config.php
sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php
sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php

# Step 6a - Permissions 
usermod -a -G apache ec2-user   
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

# STEP 7 Create Wordpress DB
echo "CREATE DATABASE $DBName;" >> /tmp/db.setup
echo "CREATE USER '$DBUser'@'localhost' IDENTIFIED BY '$DBPassword';" >> /tmp/db.setup
echo "GRANT ALL ON $DBName.* TO '$DBUser'@'localhost';" >> /tmp/db.setup
echo "FLUSH PRIVILEGES;" >> /tmp/db.setup
mysql -u root --password=$DBRootPassword < /tmp/db.setup
sudo rm /tmp/db.setup


####################
### DB MIGRATION ###
####################

# Backup of Source Database
mysqldump -u root -p $DBName db-backup.sql

# Restore to Destination Database
mysql -h $RDSDNSName -u $RDSUserName -p $RDSDBName < db-backup.sql

# Remove local copy of DB backup
# sudo rm db-backup.sql

# Change WP Config
cd /var/www/html

# Use sed to replace placeholders in wp-config.php
sed -i "s/define( 'DB_NAME', '[^']*' );/define( 'DB_NAME', '$DBName' );/g" wp-config.php
sed -i "s/define( 'DB_USER', '[^']*' );/define( 'DB_USER', '$DBUser' );/g" wp-config.php
sed -i "s/define( 'DB_PASSWORD', '[^']*' );/define( 'DB_PASSWORD', '$DBPassword' );/g" wp-config.php
sed -i "s/define( 'DB_HOST', '[^']*' );/define( 'DB_HOST', '$RDSDNSName' );/g" wp-config.php

# Stop local db service
# systemctl stop mariadb