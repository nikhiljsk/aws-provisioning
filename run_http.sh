#!/bin/bash
sudo -i
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl status httpd
sudo echo '<center><h1>HTTP Server is Running! This instance is in the private subnet </h1></center>' > /var/www/html/index.html

# mysql -h  -u admin -p Smarty*777