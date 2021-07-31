#!/bin/bash

echo "######################   START OF Setup Anchore Scan Environment   ######################"
echo

sudo mkdir -p /usr/lib/aevolume/

sudo chmod 777 /etc/profile.d
sudo cat > /etc/profile.d/update_path_var.sh << EOF
export PATH=$PATH:/usr/local/bin
EOF
sudo chmod 755 /etc/profile.d

echo "Downloading Docker Compose...."
wget https://github.com/docker/compose/releases/download/1.24.0/docker-compose-`uname -s`-`uname -m`
sudo mv docker-compose-`uname -s`-`uname -m` /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo "Downloading Docker Compose.... Done!!!"

echo "Downloading Anchore Engine.... "
sudo docker pull docker.io/anchore/anchore-engine:latest
echo "Downloading Anchore Engine.... Done!!!"

sudo yum install -y python3
wget https://bootstrap.pypa.io/pip/3.5/get-pip.py
python3 get-pip.py --force-reinstall

echo "Downloading Anchore CLI.... "
pip3 install anchorecli

pip3 freeze | grep anchorecli

sudo docker ps --all
echo "Downloading Anchore CLI.... Done!!!"


echo
echo "######################   END OF Setup Anchore Scan Environment   ######################"


