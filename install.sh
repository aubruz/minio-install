#!/bin/bash

useradd -r minio-user -s /sbin/nologin

if [ ! -f "/usr/local/bin/minio" ]; then
  wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio
  chmod +x /usr/local/bin/minio
  chown minio-user:minio-user /usr/local/bin/minio
fi
if [ ! -f "/usr/local/bin/mc" ]; then
  wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc
  chmod +x /usr/local/bin/mc
fi

#Ask for configurations parameters
read -p 'Minio data path: ' minio_data_path
read -p 'MINIO_ACCESS_KEY: ' minio_access_key
read -sp 'MINIO_SECRET_KEY: ' minio_secret_key
echo ''

while true
do
  read -p 'Minio port [default 9000]: ' minio_port
  [[ $minio_port =~ ^([0-9]+|'')$ ]] || { echo "Enter a valid number"; continue; }
  if (( minio_port >= 1 && minio_port <= 65535 )); then
    break;
  elif [ -z "$minio_port" ];then
    #Set default port
    minio_port=9000
    break;
  else
    echo "Port not valid!"
  fi
done


while true
do
 read -r -p 'Do you want the script to open the firewall port for you? [y/N] ' open_fw_port
 case $open_fw_port in
     [yY][eE][sS]|[yY])
 open_fw_port=true
 break
 ;;
     [nN][oO]|[nN]|"")
 open_fw_port=false
 break
        ;;
     *)
 echo "Invalid..."
 ;;
 esac
done


sudo chown minio-user $minio_data_path && sudo chmod u+rxw $minio_data_path


if [ ! -f "/etc/firewalld/services/minio.xml" ] && [ -d "/etc/firewalld/services" ]; then
cat > /etc/firewalld/services/minio.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>Minio Server</short>
  <description>Minio Server, object storage server.</description>
  <port protocol="tcp" port="9000"/>
</service>
EOF
fi

systemctl_reload=false
if [ -f "/etc/systemd/system/minio.service" ]; then
  systemctl_reload=true
fi

if [ ! -f "/etc/default/minio" ]; then
cat > /etc/default/minio << EOF
MINIO_ACCESS_KEY="$minio_access_key"
MINIO_VOLUME="$minio_data_path"
MINIO_OPTS="--address :$minio_port"
MINIO_SECRET_KEY="$minio_secret_key"
EOF
fi

cat > /etc/systemd/system/minio.service << EOF
[Unit]
Description=Minio Server
Documentation=https://docs.min.io
After=network-online.target
Wants=network-online.target
AssertFileIsExecutable=/usr/local/bin/minio

[Service]
User=minio-user
Group=minio-user
EnvironmentFile=/etc/default/minio
ExecStartPre=/bin/bash -c "if [ -z \"\${MINIO_VOLUME}\" ]; then echo \"Variable MINIO_VOLUME not set in /etc/default/minio\"; exit 1; fi"
Type=simple
ExecStart=/usr/local/bin/minio server \$MINIO_OPTS \$MINIO_VOLUME
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutSec=0
RestartSec=2
# Let systemd restart this service always
Restart=always
# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536
# Disable timeout logic and wait until process is stopped
TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF


if [ "$open_fw_port" = true ];then
  echo -e "Opening port $minio_port in firewalld: "
  if [ $minio_port -eq 9000 ]; then
    firewall-cmd --add-service=minio --permanent --zone=public
  else
    firewall-cmd --add-port=$minio_port/tcp --permanent --zone=public
  fi
  echo "Reloading firewalld: "
  firewall-cmd --reload
fi

if [ "$systemctl_reload" = true ]; then
  systemctl daemon-reload
fi

echo "Enabling minio server..."
systemctl enable minio
echo "Starting minio server..."
systemctl restart minio
echo "Done!"
