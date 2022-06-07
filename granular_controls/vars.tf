variable "profile" {
    description = "AWS creds to use"
    default = "default"
}
variable "region" {
        default = "eu-west-2"
}

variable "access_key" {
    description = "Access Key"
    default = ""
}

variable "secret_key" {
    description = "Secret Key"
    default = ""
}
variable "username" {
    default = "Mark"
}

data "aws_caller_identity" "current" {}
