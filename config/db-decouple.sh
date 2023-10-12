# https://learn.cantrill.io/courses/1820301/lectures/41301418

# Backup of Source Database
mysqldump -u root -p a4lwordpress > a4lwordpress.sql


# Restore to Destination Database
mysql -h privateipof_a4l-mariadb -u a4lwordpress -p a4lwordpress < a4lwordpress.sql 

# Change WP Config
cd /var/www/html
sudo nano wp-config.php

replace
/** MySQL hostname */
define('DB_HOST', 'localhost');

with 
/** MySQL hostname */
define('DB_HOST', 'REPLACEME_WITH_MARIADB_PRIVATEIP'); 

sudo service mariadb stop