#!/bin/bash
# Update the OS.
yum update –y

# Install Apache.
yum install -y httpd

# Start, enable and display the status of Apache.
commands=('start' 'enable' 'status')
for i in "${commands[@]}"
do
   systemctl $i httpd
done
