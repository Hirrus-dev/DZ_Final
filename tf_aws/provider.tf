variable "aws_accesskey" {}
variable "aws_secretkey" {}
variable "pub_key" {}
variable "pvt_key" {}
variable "ansible_user_password" {}

provider "aws" {
    access_key = var.aws_accesskey
    secret_key = var.aws_secretkey
    region = "us-west-2"
}
