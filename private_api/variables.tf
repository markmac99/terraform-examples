variable "profile" {
  description = "AWS creds to use"
  default     = "default"
}
variable "region" {
  default = "eu-west-2"
}

variable "access_key" {
  description = "Access Key"
  default     = ""
}

variable "secret_key" {
  description = "Secret Key"
  default     = ""
}

data "aws_vpc" "mainvpc" {
  tags = {
    Name = "MainVPC"
  }
}
data "aws_subnet" "ec2subnet" {
  tags = {
    Name = "ec2Subnet"
  }
}

