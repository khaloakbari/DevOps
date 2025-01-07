#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi


# Configure the network interface
cat <<EOF > /etc/netplan/50-cloud-init.yaml
network:
    ethernets:
        ens34:
            addresses:
            - 150.10.10.1/24
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

# Update and install NGINX
apt update && apt install -y nginx netplan.io

# Create the website directory
mkdir -p /var/www/devops.com

# Create the index.html file
cat <<EOF > /var/www/devops.com/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Web Server 1</title>
    <style>
        body {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
        }
        h1 {
            font-size: 5rem;
            color: red;
        }
    </style>
</head>
<body>
    <h1>Web Server 1</h1>
</body>
</html>
EOF

# Set permissions for the website directory
chown -R www-data:www-data /var/www/devops.com
chmod -R 755 /var/www/devops.com

# Configure NGINX
cat <<EOF > /etc/nginx/sites-available/devops.com
server {
       listen 80;
       listen [::]:80;

       server_name devops.com;

       root /var/www/devops.com;
       index index.html;

       location / {
               try_files \$uri \$uri/ =404;
       }
}
EOF

# Enable the site configuration
ln -s /etc/nginx/sites-available/devops.com /etc/nginx/sites-enabled/

# Test NGINX configuration
nginx -t

# Restart NGINX service
systemctl restart nginx



echo "Web server setup completed successfully."
