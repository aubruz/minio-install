#!/bin/bash

while true
do
 read -r -p 'Do you want the script to close the firewall port for you? [y/N] ' close_fw_port
 case $close_fw_port in
     [yY][eE][sS]|[yY])
 read -p 'Minio port used [default 9000]: ' minio_port
 if [ $minio_port -eq 9000 ]; then
   if [ -x "$(command -v ufw)" ]; then
     ufw deny 9000
   elif [ -x "$(command -v firewall-cmd)" ]; then
    firewall-cmd --remove-service=minio --permanent --zone=public
    echo "Reloading firewalld: "
    firewall-cmd --reload
   fi
 else
   if [ -x "$(command -v ufw)" ]; then
     ufw deny $minio_port
   elif [ -x "$(command -v firewall-cmd)" ]; then
    firewall-cmd --remove-port=$minio_port/tcp --permanent --zone=public
    echo "Reloading firewalld: "
    firewall-cmd --reload
   fi
 fi


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
if [ -f "/etc/defautl/minio" ]; then
  rm -f /etc/defautl/minio
fi
userdel minio-user
