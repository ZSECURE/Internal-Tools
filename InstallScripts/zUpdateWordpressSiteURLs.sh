#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 -d <wordpress_directory> -u <site_url>"
  echo "  -d <wordpress_directory> : Path to the WordPress installation directory"
  echo "  -u <site_url>            : New site URL (e.g., http://example.com)"
  exit 1
}

# Parse command line arguments
while getopts "d:u:" opt; do
  case $opt in
    d)
      WP_DIR=$OPTARG
      ;;
    u)
      SITE_URL=$OPTARG
      ;;
    *)
      usage
      ;;
  esac
done

# Check if both arguments are provided
if [ -z "$WP_DIR" ] || [ -z "$SITE_URL" ]; then
  usage
fi

# Check if wp-config.php exists
WP_CONFIG="$WP_DIR/wp-config.php"
if [ ! -f "$WP_CONFIG" ]; then
  echo "Error: wp-config.php not found in the specified directory."
  exit 1
fi

# Update the site URL in wp-config.php
# Note: This adds the site URL definition if it doesn't already exist
if grep -q "define('WP_HOME'" "$WP_CONFIG"; then
  sed -i "s|define('WP_HOME'.*|define('WP_HOME', '$SITE_URL');|" "$WP_CONFIG"
else
  echo "define('WP_HOME', '$SITE_URL');" >> "$WP_CONFIG"
fi

if grep -q "define('WP_SITEURL'" "$WP_CONFIG"; then
  sed -i "s|define('WP_SITEURL'.*|define('WP_SITEURL', '$SITE_URL');|" "$WP_CONFIG"
else
  echo "define('WP_SITEURL', '$SITE_URL');" >> "$WP_CONFIG"
fi

echo "Updated WordPress site URLs in wp-config.php to $SITE_URL"
