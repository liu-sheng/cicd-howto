#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "You should run this script as root."
    exit 1
fi

# Add user zuul and generate ssh key if not exits
if ! id -u zuul > /dev/null 2>&1; then
    useradd -m -d /home/zuul -s /bin/bash zuul
    echo zuul:zuul | chpasswd
    su - zuul -c "
        ssh-keygen -f /home/zuul/.ssh/id_rsa -t rsa -N ''
        cat /home/zuul/.ssh/id_rsa.pub > /home/zuul/.ssh/authorized_keys
    "
fi

mkdir -p /etc/zuul
mkdir -p /var/log/zuul
mkdir -p /var/lib/zuul/builds
chown -R zuul:zuul /var/lib/zuul

CURR_DIR=$(cd $(dirname "$0") && pwd)
CONF_DIR=/etc/zuul

for config in $(ls $CURR_DIR/conf)
do
    envsubst < "$CURR_DIR/conf/$config" > "$CONF_DIR/$config"
done

# Install dependencies
apt update && apt upgrade -y
apt install python python-pip python3 python3-pip python3-crypto -y
apt install mariadb-server mariadb-client python-pymysql -y

# Install mysql
mysql -sfu root < "$CURR_DIR/conf/mysql_secure_installation.sql"

# Install Zuul v3
cd /home/zuul
git clone https://github.com/openstack-infra/zuul
cd zuul
pip3 install -r requirements.txt
pip3 install -e .
