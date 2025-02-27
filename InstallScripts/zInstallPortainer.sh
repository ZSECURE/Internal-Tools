#!/bin/bash

# Script to install Portainer Community Edition on Ubuntu

# Update package list and install prerequisites
sudo apt update
sudo apt install -y curl

# Create a volume for Portainer data
sudo docker volume create portainer_data

# Run the Portainer container
sudo docker run -d \
  -p 8000:8000 \
  -p 9443:9443 \
  --name=portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:lts

echo "Portainer Community Edition has been installed and started."
echo "Access it at http://<your-server-ip>:9443"
