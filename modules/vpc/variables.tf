#VPC

variable "region" {
  type = string
  default = "us-east-1"
}

variable "vpc_name" {
  type = string
  default = "VPC"
}
variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

