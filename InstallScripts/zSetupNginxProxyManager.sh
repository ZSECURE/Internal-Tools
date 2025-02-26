#!/bin/bash

# Script to set up Nginx Proxy Manager on Ubuntu

# Create a directory for Nginx Proxy Manager
mkdir -p /opt/nginx-proxy-manager
cd /opt/nginx-proxy-manager

# Create a docker-compose.yml file
cat <<EOF > docker-compose.yml
version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: always
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    environment:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "npm"
      DB_MYSQL_NAME: "npm"
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt

  db:
    image: 'mariadb:latest'
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: 'npm'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'npm'
    volumes:
      - ./mysql:/var/lib/mysql
EOF

# Start Nginx Proxy Manager
docker-compose up -d

echo "Nginx Proxy Manager setup is complete."
echo "Access it at http://<your-server-ip>:81 with default credentials (admin@example.com / changeme)."
