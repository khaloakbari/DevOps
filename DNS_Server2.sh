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
            - 10.10.10.2/24
            nameservers:
                addresses:
                - 185.51.200.2
                - 178.22.122.100
                search: []
            routes:
            -   to: default
                via: 10.10.10.254
    version: 2
EOF

# Apply the network configuration
netplan apply

# Configure named.conf.options
cat <<EOF > /etc/bind/named.conf.options
acl "trusted" {
    10.10.10.1;       # ns1
    150.10.10.0/24;   # ns2
    10.10.10.0/24;    # cache server
};

options {
    directory "/var/cache/bind";

    recursion yes; # enables recursive queries
    allow-recursion { trusted; };
    allow-query { trusted; };

    listen-on { 127.0.0.1; 10.10.10.2; }; # ns2 private IP address - listen on private network only

    forwarders {
        8.8.8.8;
        185.51.200.2;
    };
    forward only;

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

zone "devops.com" {
    type slave;
    masters { 10.10.10.1; };
    file "/etc/bind/zones/devops.com.deb";
    allow-transfer { 10.10.10.1; };
};
EOF

# Restart Bind9 service
systemctl restart bind9

# Enable Bind9 to start on boot
systemctl enable bind9

echo "Secondary DNS server setup completed successfully."
