#!/bin/bash

name="vadapalli"
s3_bucket="vadapallisaimaruthi"

#update the ubuntu 

sudo apt update -y
echo "updated the ubuntu"

#Check is Apache2 is install

if [[ apache2 == $(dpkg --get-selections apache2 | awk '{print $1}') ]]; 
then
	echo "Apache2 is already installed"
else	
	apt install apache2 -y
	echo "Apache2 is installed Now!"
fi

#check that Apache2 service is running

running=$(systemctl status apache2 | grep active | awk '{print $3}' | tr -d '()')
if [[ running == ${running} ]] ; 
then
	echo "Apache is already running successfully"
else
	systemctl start apache2
	echo "Apache2 is running Now!"
fi

#check Apache2 service is enable
enabled=$(systemctl is-enabled apache2 | grep "enabled")
if [[ enabled == ${enabled} ]] ; 
then
	echo "Apache2 Service is Enabled successfully"
else	
	systemctl enable apache2
	echo"Apache2 Service is Enabled Now!"
fi

#create filename

timestamp=$(date '+%d%m%Y-%H%M%S')

#create tar file and contains log files of apache2 server

cd /var/log/apache2
tar -cf /tmp/${name}-httpd-logs-${timestamp}.tar *.log

#copy logs to s3

if [[ -f /tmp/${name}-httpd-logs-${timestamp}.tar ]]; 
then
	aws s3 cp /tmp/${name}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/${name}-httpd-logs-${timestamp}.tar

fi

# Check if inventory is exists or not,if not then create a inventory.html 	

if [[ ! -f /var/www/html/inventory.html ]]; 
then
	echo -e 'Log Type\t-\tTime Created\t-\tType\t-\tSize' > /var/www/html/inventory.html
fi

# Send Logs into the file

if [[ -f /var/www/html/inventory.html ]]; 
then
	size=$(du -h /tmp/${name}-httpd-logs-${timestamp}.tar | awk '{print $1}')
	echo -e "httpd-logs\t-\t${timestamp}\t-\ttar\t-\t${size}" >> /var/www/html/inventory.html
fi

#veriyfying logs files

cd /var/www/html/
cat inventory.html

# Creating a cron job that runs service every 1 day interval

if [[ ! -f /etc/cron.d/automation ]]; 
then
	echo "0 0 * * * root /root/Automation_Project/automation.sh" >> /etc/cron.d/automation
	echo "Cronjob is created sucessfully"
else	
	echo "cronjob is already running" 
fi
