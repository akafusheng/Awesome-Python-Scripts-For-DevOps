#!/bin/bash

# Define variables
MYSQL_DIR="/opt/cosmo/com/cosmo-mysql"
MYSQL_SERVICE="/etc/init.d/mysqld"

# Confirm with the user
read -p "Are you sure you want to uninstall MySQL from $MYSQL_DIR? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Uninstallation canceled."
  exit 0
fi

# Stop MySQL service
if [ -f "$MYSQL_SERVICE" ]; then
  echo "Stopping MySQL service..."
  $MYSQL_SERVICE stop
fi

# Remove MySQL directories
if [ -d "$MYSQL_DIR" ]; then
  echo "Removing MySQL directory: $MYSQL_DIR"
  rm -rf "$MYSQL_DIR"
else
  echo "MySQL directory not found: $MYSQL_DIR"
fi

# Remove symbolic links and system files
if [ -f /usr/bin/mysql ]; then
  echo "Removing symbolic link: /usr/bin/mysql"
  rm -f /usr/bin/mysql
fi

if [ -f /usr/bin/mysqldump ]; then
  echo "Removing symbolic link: /usr/bin/mysqldump"
  rm -f /usr/bin/mysqldump
fi

if [ -f "$MYSQL_SERVICE" ]; then
  echo "Removing MySQL service file: $MYSQL_SERVICE"
  rm -f "$MYSQL_SERVICE"
fi

if [ -f /etc/my.cnf ]; then
  echo "Removing configuration file: /etc/my.cnf"
  rm -f /etc/my.cnf
fi

# Remove MySQL user and group
if id -u mysql >/dev/null 2>&1; then
  echo "Removing MySQL user..."
  userdel -r mysql
fi

if grep -q "^mysql:" /etc/group; then
  echo "Removing MySQL group..."
  groupdel mysql
fi

# Finish
echo "MySQL uninstallation complete."
