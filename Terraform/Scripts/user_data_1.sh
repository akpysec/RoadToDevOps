#!/bin/bash
yum -y update
yum -y install httpd
sudo service httpd start
chkconfig httpd on
