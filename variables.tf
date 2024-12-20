#VPC

variable "vpc_name" {
  type = string
  default = "VPC"
}
variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "vpc_azs" {
  type = map(string)
  default = {
    "az1" = "us-east-1a"
    "az2" = "us-east-1b"
    "az3" = "us-east-1c"
  }
}