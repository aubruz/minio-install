#!/bin/bash

while true
do
 read -r -p 'Do you want the script to close the firewall port for you? [y/N] ' close_fw_port
 case $close_fw_port in
     [yY][eE][sS]|[yY])
 read -p 'Minio port used [default 9000]: ' minio_port
 if [ $minio_port -eq 9000 ]; then
   firewall-cmd --remove-service=minio --permanent --zone=public
 else
   firewall-cmd --remove-port=$minio_port/tcp --permanent --zone=public
 fi
 echo "Reloading firewalld: "
 firewall-cmd --reload

 break
 ;;
     [nN][oO]|[nN]|"")
 close_fw_port=false
 break
        ;;
     *)
 echo "Invalid..."
 ;;
 esac
done

echo "Stoping minio server..."
systemctl disable minio
systemctl stop minio
if [ -f "/etc/systemd/system/minio.service" ]; then
  rm -f /etc/systemd/system/minio.service
fi
if [ -f "/etc/firewalld/services/minio.xml" ]; then
  rm -f /etc/firewalld/services/minio.xml
fi
if [ -f "/usr/local/bin/minio" ]; then
  rm -f /usr/local/bin/minio
fi
if [ -f "/usr/local/bin/mc" ]; then
  rm -f /usr/local/bin/mc
fi
if [ -f "/etc/default/minio" ]; then
  rm -f /etc/default/minio
fi

userdel minio-user
