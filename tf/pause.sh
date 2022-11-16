# TODO: Have these injected at runtime and not stored
secrets_path=$HOME/EC2Secrets

# Set up ssh login pre-requisites so that Visual Studio Code can be launched automatically
ssh-add $secrets_path'/ec2key.pem'
export TF_VAR_trade_ssh_public_key=$(cat $secrets_path'/publicKey.pem')

# Set up AWS pre-requisites
export TF_VAR_trade_region="us-west-2"
export TF_VAR_trade_availability_zone="us-west-2b"

# Add the IP of the local machine running this script to the list of allowed IPs
local_ip=$(curl -s ifconfig.me)
local_ip+="/32" # Add the CIDR notation

export TF_VAR_client_ip=$local_ip

# Check to see if the IP is set
if [ -z "$TF_VAR_client_ip" ]; then
    echo "The IP for this machine to enable the connection to the EC2 instance is not set"
    exit 1
fi

terraform destroy -auto-approve \
	--target=aws_instance.trade_ec2_spot \
	--target=aws_eip.trade_ip
