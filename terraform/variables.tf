variable "aws_region" {
  default = "ap-southeast-1"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS – Singapore region"
  default     = "ami-0df7a207adb9748c7"
}

variable "key_name" {
  description = "Your AWS Key Pair name"
  default     = "aupp-lms-key"
}