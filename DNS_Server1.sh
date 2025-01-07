#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update and install Bind9
apt update && apt install -y bind9 netplan.io

# Configure network interface
cat <<EOF > /etc/netplan/50-cloud-init.yaml
network:
    ethernets:
        ens34:
            addresses:
            - 10.10.10.1/24
            nameservers:
                addresses:
                - 8.8.8.8
                - 4.2.2.4
                search: []
            routes:
            -   to: default
                via: 10.10.10.254
    version: 2
EOF

# Apply the network configuration
netplan apply

# Create zones directory
mkdir -p /etc/bind/zones

# Create zone file for devops.com
cat <<EOF > /etc/bind/zones/devops.com.deb
\$TTL 3600

@ IN SOA ns1.devops.com. admin.devops.com. (
    2024123114 ; Serial
    3600       ; Refresh
    1800       ; Retry
    604800     ; Expire
    86400      ; Minimum TTL
)

@ IN NS ns1.devops.com.
@ IN NS ns2.devops.com.

@ IN A 150.10.10.101
@ IN A 150.10.10.100
www IN A 150.10.10.101
www IN A 150.10.10.100
ns1 IN A 10.10.10.1
ns2 IN A 10.10.10.2
EOF

# Configure named.conf.options
cat <<EOF > /etc/bind/named.conf.options
acl "trusted" {
    10.10.10.0/24; # ns1
    127.0.0.1;    # local
    10.10.10.2;   # ns2
};

options {
    directory "/var/cache/bind";

    recursion no; # disable recursive queries

    allow-recursion { trusted; };
    allow-query { trusted; };

    listen-on { 127.0.0.1; 10.10.10.1; }; # ns1 private IP address - listen on private network only

    allow-transfer { trusted; }; # disable zone transfers by default

    dnssec-validation no;

    listen-on-v6 { any; };
};
EOF

# Configure named.conf.local
cat <<EOF > /etc/bind/named.conf.local
//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";

zone "reza.com" {
    type master;
    file "/etc/bind/zones/reza.com.deb";
    allow-transfer { 10.10.10.2; };
};

zone "devops.com" {
    type master;
    file "/etc/bind/zones/devops.com.deb";
    allow-transfer { 10.10.10.2; };
};
EOF    

# Restart Bind9 service
systemctl restart bind9

# Enable Bind9 to start on boot
systemctl enable bind9

echo "DNS server setup completed successfully."
