#!/bin/sh

sudo apt-get update
sudo apt-get -y install unzip

# install script is different for ARM
echo "Installing AWS CLI v2..."
cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install

export AWS_DEFAULT_REGION=$( curl -s http://169.254.169.254/latest/meta-data/placement/region )
EFS_ID=$( aws ssm get-parameter --name trade_efs_id --output text --query 'Parameter.Value' )
ACCESS_POINT_DATA=$( aws ssm get-parameter --name trade_efs_trade_ap --output text --query 'Parameter.Value' )
ACCESS_POINT_DOCKER=$( aws ssm get-parameter --name trade_efs_docker_ap --output text --query 'Parameter.Value' )
EFS_MOUNT_AZ=$( aws ssm get-parameter --name trade_availability_zone --output text --query 'Parameter.Value' )
IP_ALLOC_ID=$( aws ssm get-parameter --name trade_ip_allocation_id --output text --query 'Parameter.Value' )
SSH_PUBLIC_KEY=$( aws ssm get-parameter --name trade_ssh_key --output text --query 'Parameter.Value' )

# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
INSTANCE_ID=$( curl -s http://169.254.169.254/latest/meta-data/instance-id )
HOME_DIR=/home/ubuntu

echo "Installing Amazon EFS file system utilities..."
sudo apt-get update
sudo apt-get -y install git binutils
git clone https://github.com/aws/efs-utils
cd efs-utils
./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb
cd -

sudo apt-get update
sudo apt-get -y install wget

if echo $(python3 -V 2>&1) | grep -e "Python 3.6"; then
    sudo wget https://bootstrap.pypa.io/pip/3.6/get-pip.py -O /tmp/get-pip.py
elif echo $(python3 -V 2>&1) | grep -e "Python 3.5"; then
    sudo wget https://bootstrap.pypa.io/pip/3.5/get-pip.py -O /tmp/get-pip.py
elif echo $(python3 -V 2>&1) | grep -e "Python 3.4"; then
    sudo wget https://bootstrap.pypa.io/pip/3.4/get-pip.py -O /tmp/get-pip.py
else
    sudo apt-get -y install python3-distutils
    sudo wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py
fi

sudo python3 /tmp/get-pip.py
sudo pip3 install botocore

echo "Mount EFS file system into home directory"
mount -t efs -o az=$EFS_MOUNT_AZ,tls,accesspoint=$ACCESS_POINT_DATA $EFS_ID:/ $HOME_DIR
mkdir -p /docker
mount -t efs -o az=$EFS_MOUNT_AZ,tls,accesspoint=$ACCESS_POINT_DOCKER $EFS_ID:/ /docker

echo "Preparing Bash profile..."
[ ! -f $HOME_DIR/.bashrc ] && {
  sudo -u ubuntu cp -r /etc/skel/. $HOME_DIR/
}

echo "Inserting public SSH key into EFS home directory..."
sudo -u ubuntu mkdir $HOME_DIR/.ssh
sudo -u ubuntu chmod 0700 $HOME_DIR/.ssh
sudo -u ubuntu touch $HOME_DIR/.ssh/authorized_keys
grep -q -F "${SSH_PUBLIC_KEY}" $HOME_DIR/.ssh/authorized_keys || {
  echo "${SSH_PUBLIC_KEY}" | sudo -u ubuntu tee -a "${SSH_PUBLIC_KEY}" $HOME_DIR/.ssh/authorized_keys
}

GIT_REPO=naumoffp/EC2Trade
RAW_GIT_URL=https://raw.githubusercontent.com/${GIT_REPO}/master/EC2Trade/scripts
AUTO_INSTALL_SCRIPTS="01-install-tmux.auto-install.sh 02-install-docker.auto-install.sh"

for script in $AUTO_INSTALL_SCRIPTS
do
  echo "Downloading ${RAW_GIT_URL}/$script..."
  curl -L -s ${RAW_GIT_URL}/$script | bash
  echo "$script done at $( date )" >> /tmp/ec2trade-installer.log
done

echo "Associating Elastic IP..."
aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id $IP_ALLOC_ID
