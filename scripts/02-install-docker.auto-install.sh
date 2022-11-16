#!/bin/sh

DOCKER_VAR_LIB=/docker
mkdir -p $DOCKER_VAR_LIB

sudo apt-get update
sudo apt-get -y install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Manage Docker as a non-root user
sudo groupadd docker
sudo usermod -aG docker ubuntu

echo "Changing Docker data root location to ${DOCKER_VAR_LIB}..."
cp /etc/sysconfig/docker /etc/sysconfig/docker.$( date +%s ).backup
sed -i "s@OPTIONS=\"--default-ulimit@OPTIONS=\"--data-root $DOCKER_VAR_LIB --default-ulimit@g" /etc/sysconfig/docker
