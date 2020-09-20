#!/bin/bash

sudo -Hiu postgres /etc/init.d/postgresql start

if [[ -f /var/lib/postgres/12/main/postgresql.auto.conf ]]; then
sudo -Hiu postgres createuser root
sudo -Hiu postgres createdb -O root gvmd
sudo -Hiu postgres psql -c 'create role dba with superuser noinherit;' gvmd
sudo -Hiu postgres psql -c 'grant dba to root;' gvmd
sudo -Hiu postgres psql -c 'create extension "uuid-ossp";' gvmd
sudo -Hiu postgres /etc/init.d/postgresql restart
fi

redis-server /etc/redis/redis.conf &
sleep 15
ls -la /run/redis-openvas
chmod 777 -R /opt
chown gvm:gvm -R /opt

/usr/bin/python3 /opt/gvm/bin/ospd-openvas -L DEBUG --pid-file /opt/gvm/var/run/ospd-openvas.pid --log-file /opt/gvm/var/log/gvm/ospd-openvas.log --lock-file-dir /opt/gvm/var/run --unix-socket /opt/gvm/var/run/ospd.sock
sleep 60

ls -la /opt/gvm/var/run
sleep 5
/opt/gvm/sbin/openvas --update-vt-info
sleep 15
# Start GVM
/opt/gvm/sbin/gvmd --osp-vt-update=/opt/gvm/var/run/ospd.sock --unix-socket /opt/gvm/var/run/gvmd.sock
# Start GSA
gvm-manage-certs -a
sudo /opt/gvm/sbin/gsad --listen=0.0.0.0 --port=443 --no-redirect --unix-socket=/opt/gvm/var/run/gvmd.sock

# Check the status
#sudo -Hiu gvm echo "ps aux | grep -E "ospd-openvas|gsad|gvmd" | grep -v grep" | sudo -Hiu gvm tee -a /opt/gvm/.bashrc

# Wait a moment for the above to start up

# Create GVM Scanner
sleep 15
/opt/gvm/sbin/gvmd --create-scanner="Created OpenVAS Scanner" --scanner-type="OpenVAS" --scanner-host=/opt/gvm/var/run/ospd.sock && /opt/gvm/sbin/gvmd --get-scanners && export UUID=$(/opt/gvm/sbin/gvmd --get-scanners | grep Created | awk '{print $1}') && /opt/gvm/sbin/gvmd --verify-scanner=$UUID

# Create OpenVAS (GVM 11) Admin
/opt/gvm/sbin/gvmd --create-user admin --password=admin


tail -f /opt/gvm/var/log/gvm/*.log
