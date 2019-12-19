#!/bin/bash
# Update the OS.
yum update -y

# Install EPEL repository.
cd /tmp
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y epel-release-latest-7.noarch.rpm

# Update the OS again.
yum update -y

# Install OpenVPN and EasyRSA.
yum install -y openvpn easy-rsa

# Make a copy of the EasyRSA shell script.
cp -r /usr/share/easy-rsa/ /etc/openvpn/

# Create a file called 'vars' in EasyRSA's directory.
{
	echo 'set_var EASYRSA                 "/etc/openvpn/easy-rsa/vars"'
	echo 'set_var EASYRSA_PKI             "$EASYRSA/pki"'
	echo 'set_var EASYRSA_DN              "cn_only"'
	echo 'set_var EASYRSA_REQ_COUNTRY     "US"'
	echo 'set_var EASYRSA_REQ_PROVINCE    "New York"'
	echo 'set_var EASYRSA_REQ_CITY        "Brooklyn"'
	echo 'set_var EASYRSA_REQ_ORG         "it.garry CERTIFICATE AUTHORITY"'
	echo 'set_var EASYRSA_REQ_EMAIL       "it.garry@gmail.com"'
	echo 'set_var EASYRSA_REQ_OU          "ITG EASY CA"'
	echo 'set_var EASYRSA_KEY_SIZE        2048'
	echo 'set_var EASYRSA_ALGO            rsa'
	echo 'set_var EASYRSA_CA_EXPIRE       7500'
	echo 'set_var EASYRSA_CERT_EXPIRE     365'
	echo 'set_var EASYRSA_NS_SUPPORT      "no"'
	echo 'set_var EASYRSA_NS_COMMENT      "ITG CERTIFICATE AUTHORITY"'
	echo 'set_var EASYRSA_EXT_DIR         "$EASYRSA/x509-types"'
	echo 'set_var EASYRSA_SSL_CONF        "$EASYRSA/openssl-easyrsa.cnf"'
	echo 'set_var EASYRSA_DIGEST          "sha256"'
} >> /etc/openvpn/easy-rsa/vars

# Change the permissions of the 'vars' file.
chmod +x /etc/openvpn/easy-rsa/vars

# Initialize the Certificate of Authority key.
./easyrsa init-pki

# Build the Certificate of Authority key.
./easyrsa build-ca

# Build the server key.
./easyrsa gen-req it.garry nopass

# Sign the server key.
./easyrsa sign-req server it.garry

# Build the client key.
./easyrsa gen-req client01 nopass

# Sign the client key.
./easyrsa sign-req client client01

# Build the Diffie-Hellman key.
./easyrsa gen-dh

# Copy the server key and certificate into its OpenVPN directory.
openvpn_dir1 = '/etc/openvpn/server'
key_and_certs=('pki/ca.crt' 'pki/issued/it.garry.crt' 'pki/private/it.garry.key', 'pki/dh.pem')
for i in ${key_and_certs[@]}
do
	cp $i $openvpn_dir1
done

# Copy the client key and certificate into its OpenVPN directory.
openvpn_dir2 = '/etc/openvpn/client'
key_and_certs=('pki/ca.crt' 'pki/issued/client01.crt' 'pki/private/client01.key')
for i in ${key_and_certs[@]}
do 
        cp $i $openvpn_dir2
done

# Create a configuration file for OpenVPN.
{
	echo "# OpenVPN Port, Protocol, and the Tun"
	echo "port 1194"
	echo "proto udp"
	echo "dev tun"
	echo ""
	echo "# OpenVPN Server Certificate - CA, server key and certificate"
	echo "ca /etc/openvpn/server/ca.crt"
	echo "cert /etc/openvpn/server/hakase-server.crt"
	echo "key /etc/openvpn/server/hakase-server.key"
	echo ""
	echo "#DH and CRL key"
	echo "dh /etc/openvpn/server/dh.pem
	echo "crl-verify /etc/openvpn/server/crl.pem"
	echo ""
	echo "# Network Configuration - Internal network"
	echo "# Redirect all Connection through OpenVPN Server"
	echo "server 10.5.0.0 255.255.255.0"
	echo 'push "redirect-gateway def1"'
	echo ""
	echo "# Using the DNS from https://dns.watch"
	echo "push 'dhcp-option DNS 84.200.69.80'"
	echo "push 'dhcp-option DNS 84.200.70.40'"
	echo ""
	echo "#Enable multiple clients to connect with the same certificate key"
	echo "duplicate-cn"
	echo ""
	echo "# TLS Security"
	echo "cipher AES-256-CBC"
	echo "tls-version-min 1.2"
	echo "tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-CBC-SHA256:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-128-CBC-SHA256"
	echo "auth SHA512"
	echo "auth-nocache"
	echo ""
	echo "# Other Configuration"
	echo "keepalive 20 60"
	echo "persist-key"
	echo "persist-tun"
	echo "compress lz4"
	echo "daemon"
	echo "user nobody"
	echo "group nobody"
	echo ""
	echo "# OpenVPN Log"
	echo "log-append /var/log/openvpn.log"
	echo "verb 3"
} >> /etc/openvpn/server/server.conf

# Enable port forwarding.
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# Configure the firewall.
firewall_cmd = 'firewall-cmd --permanent'
firewall_opts=('--add-service=openvpn' '--zone-trusted --add-service=openvpn' '--zone=trusted --add-interface=tun0' '--add-masquerade')
for i in ${firewall_opts[@]}
do
	$firewall_cmd $i
done

# Enable NAT for OpenVPN internal IP address '10.5.0.0/24'
# to the external IP address 'SERVERIP'.

SERVERIP=$(ip route get 1.1.1.1 | awk 'NR==1 {print $(NF-2)}')
firewall-cmd --permanent --direct --passthrough ipv4 -t nat -A POSTROUTING -s  10.5.0.0/24 -o $SERVERIP -j MASQUERADE

# Reload the firewall.
firewall-cmd --reload

# Start, enable and check the status of OpenVPN.
sys_commands=('start' 'enable' 'status')
for i in ${sys_commands[@]}
do
	systemctl $i openvpn-server@server
done
