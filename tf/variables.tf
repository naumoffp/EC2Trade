# The region where EC2Trade will run
variable "trade_region" {
  type    = string
  default = null
}

# The region where EC2Trade will host the AWS Elastic File System (EFS) One Zone Storage
# TODO: Make one zone storage optional
variable "trade_availability_zone" {
  type    = string
  default = null
}

# The maximum bidding price for an AWS EC2 Spot Instance
# The agreed upon price may be lower during the spot instance request step
variable "trade_price" {
  type    = string
  default = "0.005"
}

# The instance type for the AWS EC2 Spot Instance
# Ex. t3.micro or c7g.8xlarge
variable "trade_instance_type" {
  type    = string
  default = "t3.micro"
}

# The AWS S3 Bucket where EC2Trade will store the data
variable "trade_storage_bucket" {
  type    = string
  default = ""
}

# The script that EC2Trade will run after the AWS EC2 Spot Instance is launched
variable "trade_install_script" {
  type    = string
  default = "https://raw.githubusercontent.com/naumoffp/EC2Trade/main/EC2Trade/scripts/ec2trade-install.sh"
}

# The local IP address of the machine that will be used to access the EC2 instance
# This is used in the security group for AWS EC2 to allow SSH access to the EC2 instance
variable "client_ip" {
  type    = string
  default = null
}

# The SSH public key that will be used to access the AWS EC2 Spot Instance
variable "trade_ssh_public_key" {
  type    = string
  default = null
}
