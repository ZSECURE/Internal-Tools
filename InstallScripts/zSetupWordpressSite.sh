#!/bin/bash

# Script to set up a WordPress site using Docker Compose with argument parsing

# Base directory for all WordPress sites
BASE_DIR=/home/ubuntu/wordpress-sites

# Function to create a WordPress site
create_wordpress_site() {
  local site_name=$1
  local port=$2

  # Check if the port is already in use
  if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
    echo "Error: Port $port is already in use. Please choose a different port."
    exit 1
  fi

  # Create directories for the site
  mkdir -p $BASE_DIR/$site_name/html
  mkdir -p $BASE_DIR/$site_name/db

  # Create a Docker Compose file for the site
  cat <<EOF > $BASE_DIR/$site_name/docker-compose.yml
version: '3.1'
services:
  wordpress:
    image: wordpress
    restart: always
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: exampleuser
      WORDPRESS_DB_PASSWORD: examplepass
      WORDPRESS_DB_NAME: exampledb
    volumes:
      - ./html:/var/www/html
    ports:
      - "$port:80"

  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: exampledb
      MYSQL_USER: exampleuser
      MYSQL_PASSWORD: examplepass
      MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - ./db:/var/lib/mysql
EOF

  # Start the Docker containers for the site
  cd $BASE_DIR/$site_name
  docker-compose up -d

  echo "WordPress site '$site_name' has been set up and started on port $port."
  echo "Access it at http://<your-server-ip>:$port"
}

# Function to display usage
usage() {
  echo "Usage: $0 -n <site_name> -p <port>"
  echo "  -n <site_name> : Name of the WordPress site"
  echo "  -p <port>      : Port number to expose the site on"
  exit 1
}

# Parse command line arguments
while getopts "n:p:" opt; do
  case $opt in
    n)
      SITE_NAME=$OPTARG
      ;;
    p)
      PORT=$OPTARG
      ;;
    *)
      usage
      ;;
  esac
done

# Check if both arguments are provided
if [ -z "$SITE_NAME" ] || [ -z "$PORT" ]; then
  usage
fi

# Create base directory if it doesn't exist
mkdir -p $BASE_DIR

# Create and start the WordPress site
create_wordpress_site "$SITE_NAME" "$PORT"
