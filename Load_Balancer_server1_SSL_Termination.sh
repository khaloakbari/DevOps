#!/bin/bash

# Variables
PRIVATE_KEY="/root/private.key"
CSR_FILE="/root/csr.csr"
CERTIFICATE="/root/certificate.crt"
REMOTE_SERVER="user@<remote_server_ip>" # Replace with the IP or hostname of the second server
REMOTE_PATH="/root/"

# Generate a private key
echo "Generating private key..."
openssl genpkey -algorithm RSA -out $PRIVATE_KEY

# Generate a certificate signing request (CSR)
echo "Generating CSR..."
openssl req -new -key $PRIVATE_KEY -out $CSR_FILE \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=devops.com"

# Generate a self-signed certificate
echo "Generating self-signed certificate..."
openssl x509 -req -days 365 -in $CSR_FILE -signkey $PRIVATE_KEY -out $CERTIFICATE

# Verify files
echo "Generated files:"
ls -l $PRIVATE_KEY $CSR_FILE $CERTIFICATE

# Transfer files to the second server
echo "Transferring files to the second server..."
scp $PRIVATE_KEY $CERTIFICATE $REMOTE_SERVER:$REMOTE_PATH

if [ $? -eq 0 ]; then
    echo "Files transferred successfully to $REMOTE_SERVER"
else
    echo "Error in transferring files to $REMOTE_SERVER"
fi
