#!/bin/bash
sudo yum install -y httpd.x86_64
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo chmod 777 /var/www/html -R
echo "Hello World from $(hostname -f)" > /var/www/html/index.html
