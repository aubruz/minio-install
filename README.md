# Minio-install
Scripts to install and uninstall [minio server](https://docs.min.io/)

##Installation
Download and run [installation.sh](https://github.com/aubruz/minio-install/blob/master/install.sh). The script will ask for the data path, the server access key and secret key, the port you want to use and wether or not you want it to open the firewall port for you.
```
wget https://github.com/aubruz/minio-install/blob/master/install.sh
chmod +x install.sh
sudo ./install.sh
```

You can check that everything is working fine with `systemctl status minio`.

##Deinstallation
Download and run [uninstall.sh](https://github.com/aubruz/minio-install/blob/master/uninstall.sh). The script will remove all the files that the installation.sh created.

```
wget https://github.com/aubruz/minio-install/blob/master/uninstall.sh
chmod +x uninstall.sh
sudo ./uninstall.sh
```
