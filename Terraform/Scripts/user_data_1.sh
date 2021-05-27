#!/bin/bash
yum -y update
yum -y install httpd
sudo service httpd start
sudo bash -c 'echo "Hello World!" > /var/www/html/index.html'
chkconfig httpd on
