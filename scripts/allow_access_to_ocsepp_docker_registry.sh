#!/bin/bash
 
echo "######################   START OF Access to Docker Registry   ######################"
echo

source /home/cloud-user/configuration.env

if [ `id -u` -ne 0 ]; then
   echo "ERROR: This script can be executed only as sudo, Exiting...."
   exit 1
fi
 
echo "Updating /etc/hosts"
echo "${DOCKER_REGISTRY_IP} ${DOCKER_REGISTRY_NAME}" >> /etc/hosts
echo "Adding /etc/docker/daemon.json"
cat > /etc/docker/daemon.json << EOT
{
  "insecure-registries" : ["${DOCKER_REGISTRY_NAME}:5000"]
}
EOT
 
echo "Reloading Deamons"
systemctl daemon-reload
echo "Restarting Docker"
systemctl restart docker
 
echo
echo "######################   END OF Access to Docker Registry   ######################"
