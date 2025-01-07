#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Update and install required packages
apt update && apt install -y netplan.io keepalived nginx

# Configure the network
cat <<EOF > /etc/netplan/50-cloud-init.yaml
network:
    ethernets:
        ens34:
            addresses:
            - 150.10.10.10/24
            nameservers:
                addresses:
                - 10.10.10.2
                - 10.10.10.1
                search: []
            routes:
            -   to: default
                via: 150.10.10.254
    version: 2
EOF

# Apply the network configuration
netplan apply

# Configure Keepalived
cat <<EOF > /etc/keepalived/keepalived.conf
global_defs {
    router_id nginx_ha
}

vrrp_script chk_nginx {
    script "pgrep nginx"
}

vrrp_instance VI_1 {
    state MASTER # Change to BACKUP on the other server
    interface ens34 # Replace with your network interface name
    virtual_router_id 51
    priority 100 # Set to 50 on the other server
    advert_int 1

    virtual_ipaddress {
        150.10.10.100 # Replace with your desired virtual IP address
    }
    track_script {
        chk_nginx
    }
}

vrrp_instance VI_2 {
    state BACKUP # Change to BACKUP on the other server
    interface ens34 # Replace with your network interface name
    virtual_router_id 52
    priority 50 # Set to 50 on the other server
    advert_int 1

    virtual_ipaddress {
        150.10.10.101 # Replace with your desired virtual IP address
    }
    track_script {
        chk_nginx
    }
}
EOF

# Restart Keepalived service
systemctl enable keepalived
systemctl restart keepalived

# Configure NGINX load balancer
cat <<EOF > /etc/nginx/conf.d/devops.com-loadbalancer.conf
upstream backend {
    server 150.10.10.1;
    server 150.10.10.2;
}

server {
    listen 80;
    server_name devops.com;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name devops.com;

    ssl_certificate /root/certificate.crt;
    ssl_certificate_key /root/private.key;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Test and reload NGINX configuration
nginx -t && systemctl reload nginx

echo "Setup completed successfully."
