resource "aws_instance" "wordpress_instance" {
  ami             = "ami-06d2c6c1b5cbaee5f" 
  instance_type   = "t2.micro"
  security_groups = [
     "WordPress_PublicAccess",
     "ManagementAccess"
   ]
   key_name = "Terraform-EC2"

  user_data = <<-EOF
# DBName=database name for wordpress
# DBUser=mariadb user for wordpress
# DBPassword=password for the mariadb user for wordpress
# DBRootPassword = root password for mariadb

# STEP 1 - Configure Authentication Variables which are used below
DBName='mnnwordpress'
DBUser='mnnwordpress'
DBPassword='6CXT2YKa5eSCC7'
DBRootPassword='6CXT2YKa5eSCC1'

# STEP 2 - Install system software - including Web and DB
sudo dnf install wget php-mysqlnd httpd php-fpm php-mysqli mariadb105-server php-json php php-devel -y


# STEP 3 - Web and DB Servers Online - and set to startup

sudo systemctl enable httpd
sudo systemctl enable mariadb
sudo systemctl start httpd
sudo systemctl start mariadb


# STEP 4 - Set Mariadb Root Password
sudo mysqladmin -u root password $DBRootPassword


# STEP 5 - Install Wordpress
sudo wget http://wordpress.org/latest.tar.gz -P /var/www/html
cd /var/www/html
sudo tar -zxvf latest.tar.gz
sudo cp -rvf wordpress/* .
sudo rm -R wordpress
sudo rm latest.tar.gz


# STEP 6 - Configure Wordpress

sudo cp ./wp-config-sample.php ./wp-config.php
sudo sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php
sudo sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
sudo sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php   
sudo chown apache:apache * -R


# STEP 7 Create Wordpress DB

echo "CREATE DATABASE $DBName;" >> /tmp/db.setup
echo "CREATE USER '$DBUser'@'localhost' IDENTIFIED BY '$DBPassword';" >> /tmp/db.setup
echo "GRANT ALL ON $DBName.* TO '$DBUser'@'localhost';" >> /tmp/db.setup
echo "FLUSH PRIVILEGES;" >> /tmp/db.setup
mysql -u root --password=$DBRootPassword < /tmp/db.setup
sudo rm /tmp/db.setup


# STEP 8 - Browse to http://your_instance_public_ipv4_ip
              EOF

  tags = {
    Name = "WordPress_Instance"
  }

  

}
