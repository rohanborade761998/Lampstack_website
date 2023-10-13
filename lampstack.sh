#!/bin/bash
#
#
#This script automate the deployment of Ecommerce Website hosting using LAMP Stack
#
#author: Rohan Borade
#


#######################################
# Print given message in the color.
# 
# Arguments:
#   color  eg: green, red.
#######################################

    
function print_color(){

  case $1 in 
    "green") COLOR='\033[0;32m' ;;
    "red") COLOR='\033[0;31m' ;;
    "*") COLOR='\033[0m' ;;
  esac
     NC='\033[0m'
     echo -e "${COLOR} $2 ${NC}"
}



#######################################
# check status of the service. Exit if service is not acive.
# 
# Arguments:
#   service Name  eg: httpd, mariadb.
#######################################


function check_service_status(){

  is_service_active=$(systemctl is-active $1)

  if [ $is_service_active = "active" ]
  then
    print_color green "$1 service is active"
  else
    print_color red "$1 service is not active"
    exit 1
  fi

}



#######################################
# check ports are open in firewalld. Exit if port is not open.
# 
# Arguments:
#   Port Number  eg: 3306, 80.
#######################################

function check_firewalld_ports(){
  
  firewalld_ports=$(sudo firewall-cmd --list-all --zone=public  | grep -i ports)

  if [[ $firewalld_ports = *$1* ]]
  then
    print_color "green" "$1 port is open"
  else
    print_color "red" "$1 port is not open"
    exit 1
  fi
}



#######################################
# check items are present in the website.
# 
# Arguments:
#   Item Name   eg: Laptop, Drone, VR, etc.
#######################################

 
function check_items(){

  if [[ "$localhost" = *$1* ]]
  then
    print_color "green" "Item $1 is present on the webpage"
  else
    print_color "red" "Item $1 is not present on the webpage"
  fi

}








  


print_color "green" "=========================================="
print_color "green" "=========================================="
print_color "green" "-----------Deploy Pre-Requisites----------"
print_color "green" "=========================================="
print_color "green" "=========================================="

print_color "green" "=========================================="
print_color "green" "      Install and configure firewalld"
print_color "green" "=========================================="



sudo yum install -y firewalld
sudo service firewalld start
sudo systemctl enable firewalld

print_color "green" "=========================================="
check_service_status firewalld
print_color "green" "=========================================="

print_color "green" "=========================================="
print_color "green" "      Deploy and Configure Database       "
print_color "green" "=========================================="

print_color "green" "=========================================="
print_color "green" "         Instalaltion MariaDB             "
print_color "green" "=========================================="


print_color "green" "=========================================="
print_color "green" "Installing MariaDB DB Server"
print_color "green" "=========================================="
sudo yum install -y mariadb-server

print_color "green" "=========================================="
print_color "green" "       Starting MariaDB DB Server         "
print_color "green" "=========================================="


sudo service mariadb start
sudo systemctl enable mariadb

print_color "green" "=========================================="
check_service_status mariadb
print_color "green" "=========================================="


#___Configuring FirewallD rules for Database___

print_color "green" "=========================================="
print_color "green" " Configuring FirewallD rules for Database "
print_color "green" "=========================================="

sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload

print_color "green" "=========================================="
check_firewalld_ports 3306
print_color "green" "=========================================="

#___Configuring database___


print_color "green" "=========================================="
print_color "green" "          Setting Up Database             "
print_color "green" "=========================================="

cat > setup-db.sql <<-EOF
CREATE DATABASE ecomdb;
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;
EOF

sudo mysql < setup-db.sql

print_color "green" "=========================================="
print_color "green" "  Loading Inventory data to the database  "
print_color "green" "=========================================="

print_color "green" "=========================================="
print_color "green" "        Pushing Data to the database      "
print_color "green" "=========================================="

cat > db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;

INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");

EOF

sudo mysql < db-load-script.sql


mysql_db_results=$(sudo mysql -e "use ecomdb; select * from products;")

if [[ $mysql_db_results = *Laptop* ]]
then
  print_color "green" "=========================================="
  print_color "green" "             Data is present              "
  print_color "green" "=========================================="
else
  print_color "red" "Data is Empty"
  exit 1
fi 


print_color "green" "=========================================="
print_color "green" "=========================================="
print_color "green" "         Deploy and Configure Web         "
print_color "green" "=========================================="
print_color "green" "=========================================="


#___Installion Web Server___

print_color "green" "=========================================="
print_color "green" "        Installing HTTPD Webserver        "
print_color "green" "=========================================="

sudo yum install -y httpd php php-mysql
#          OR
#sudo yum install -y httpd php php-mysqlnd

print_color "green" "=========================================="
print_color "green" "   Configuring FirewallD rules for httpd  "
print_color "green" "=========================================="

sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload

print_color "green" "=========================================="
check_firewalld_ports 80
print_color "green" "=========================================="



#__Making default file as index.php___

sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf

print_color "green" "=========================================="
print_color "green" "           Starting WebServer             "
print_color "green" "=========================================="

sudo service httpd start
sudo systemctl enable httpd

print_color "green" "=========================================="
check_service_status httpd
print_color "green" "=========================================="


#___Cloning Project from GitHub____

print_color "green" "=========================================="
print_color "green" "       Clonning Project from Github       "
print_color "green" "=========================================="

sudo yum install -y git
sudo git clone https://github.com/rohanborade761998/Lampstack_website.git /var/www/html/

#___Configuring webserver to use database installed in lcoalhost____
sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php

print_color "green" "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+="
print_color "green" "======++++++====++++==++--Setup Completed--++==++++====++++++======"
print_color "green" "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+="


localhost=$(curl http://localhost)

print_color "green" "Testing common data"

for items in Laptops Drone VR Watch
do 
  check_items $items
done





