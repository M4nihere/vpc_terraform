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
    "az1" = "ap-southeast-2a"
    "az2" = "ap-southeast-2b"
    "az3" = "ap-southeast-2c"
  }
}