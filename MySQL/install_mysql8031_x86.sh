#!/bin/bash

# Define variables
MYSQL_TAR="mysql-8.0.31-linux-glibc2.12-x86_64.tar"
INSTALL_DIR="/opt/cosmo/install/x86_install"
MYSQL_DIR="/opt/cosmo/com/cosmo-mysql"
MY_CNF_PATH="$MYSQL_DIR/etc/my.cnf"
MYSQL_PASSWORD="Cosmo_6003"
IP_ADDRESS="$(hostname -I | awk '{print $1}')"
PORT="3306"

# Check if the MySQL tar file exists
if [ ! -f "$INSTALL_DIR/$MYSQL_TAR" ]; then
  echo "MySQL tar file not found: $INSTALL_DIR/$MYSQL_TAR"
  exit 1
fi

# 1.1 Check and rename existing my.cnf
if [ -f /etc/my.cnf ]; then
  echo "Renaming existing /etc/my.cnf to /etc/my.cnf.bak"
  mv /etc/my.cnf /etc/my.cnf.bak
fi

# 1.2 Extract MySQL tar file
cd $INSTALL_DIR || exit 1
tar -xvf $MYSQL_TAR

# 1.3 Move MySQL directory
if [ -d "$MYSQL_DIR" ]; then
  echo "Removing existing MySQL directory: $MYSQL_DIR"
  rm -rf "$MYSQL_DIR"
fi
mv mysql-8.0.31-linux-glibc2.12-x86_64 "$MYSQL_DIR"

# 1.4 Add mysql group and user
if ! grep -q "^mysql:" /etc/group; then
  groupadd mysql
fi
if ! id -u mysql >/dev/null 2>&1; then
  useradd -r -g mysql -s /sbin/nologin mysql
fi

# 1.5 Create necessary directories
mkdir -p $MYSQL_DIR/data
mkdir -p $MYSQL_DIR/etc
mkdir -p $MYSQL_DIR/log

# 1.6 Change ownership to mysql user and group
chown -R mysql:mysql $MYSQL_DIR

# 1.7 Create my.cnf configuration file
cat <<EOF > $MY_CNF_PATH
[mysql]
port= 3306
socket= $MYSQL_DIR/data/mysql.sock

[mysqld]
port= 3306
mysqlx_port= 33060
mysqlx_socket= $MYSQL_DIR/data/mysqlx.sock
basedir= $MYSQL_DIR
datadir= $MYSQL_DIR/data
socket= $MYSQL_DIR/data/mysql.sock
pid-file = $MYSQL_DIR/data/mysqld.pid
log-error = $MYSQL_DIR/log/error.log
# Use native password authentication
default-authentication-plugin =mysql_native_password
log_timestamps= SYSTEM
lower_case_table_names=1
general_log = 1
general_log_file=$MYSQL_DIR/log/general.log
EOF

# 1.8 Create symbolic link for my.cnf
ln -sf $MY_CNF_PATH /etc/my.cnf

# 1.9 Initialize MySQL
cd $MYSQL_DIR || exit 1
bin/mysqld --initialize-insecure --user=mysql --basedir=$MYSQL_DIR --datadir=$MYSQL_DIR/data

# 1.10 Add MySQL to the system
ln -sf $MYSQL_DIR/bin/mysql /usr/bin/mysql
ln -sf $MYSQL_DIR/bin/mysqldump /usr/bin/mysqldump
cp $MYSQL_DIR/support-files/mysql.server /etc/init.d/mysqld
chkconfig --add mysqld

# 1.11 Start MySQL database
/opt/cosmo/com/cosmo-mysql/support-files/mysql.server start

# 1.12 Set MySQL root password and configure users
$MYSQL_DIR/bin/mysql -uroot --socket=$MYSQL_DIR/data/mysql.sock <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
CREATE DATABASE mxwi DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
CREATE DATABASE nacos DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
EOF

# Output connection details
echo "MySQL Installation Complete."
echo "Connection Details:"
echo "IP Address: $IP_ADDRESS"
echo "Port: $PORT"
echo "Username: root"
echo "Password: $MYSQL_PASSWORD"

# 1.15 Restart the database to ensure all changes are applied
/opt/cosmo/com/cosmo-mysql/support-files/mysql.server restart
