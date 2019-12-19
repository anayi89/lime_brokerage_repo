#!/bin/bash

# Update the OS.
yum update -y

# Install Java.
yum install -y java-openjdk-devel java-openjdk

# Import the GPG key.
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# Create the Yum repository file for Elasticsearch.
{
     echo "[elasticsearch]"
     echo "name=Elasticsearch repository for 7.x packages"
     echo "baseurl=https://artifacts.elastic.co/packages/7.x/yum"
     echo "gpgcheck=1"
     echo "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch"
     echo "enabled=1"
     echo "autorefresh=1"
     echo "type=rpm-md"
} >> /etc/yum.repos.d/elasticsearch.repo

# Create the Yum repository file for Logstash.
{
     echo "[logstash]"
     echo "name=Logstash repository for 7.x packages"
     echo "baseurl=https://artifacts.elastic.co/packages/7.x/yum"
     echo "gpgcheck=1"
     echo "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch"
     echo "enabled=1"
     echo "autorefresh=1"
     echo "type=rpm-md"
} >> /etc/yum.repos.d/logstash.repo

# Create the Yum repository file for Kibana.
{
     echo "[kibana]"
     echo "name=Kibana repository for 7.x packages"
     echo "baseurl=https://artifacts.elastic.co/packages/7.x/yum"
     echo "gpgcheck=1"
     echo "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch"
     echo "enabled=1"
     echo "autorefresh=1"
     echo "type=rpm-md"
} >> /etc/yum.repos.d/kibana.repo

# Install Elasticsearch, Logstash & Kibana.
yum install -y elasticsearch logstash kibana

# Start Elasticsearch.
sys_array=('start' 'enable' 'status')
for i in ${sys_array[@]}
do
     systemctl $i elasticsearch
done

# Start Logstash.
sys_array=('start' 'enable' 'status')
for i in ${sys_array[@]}
do
     systemctl $i logstash
done

# Start Kibana.
sys_array=('start' 'enable' 'status')
for i in ${sys_array[@]}
do
     systemctl $i kibana
done
