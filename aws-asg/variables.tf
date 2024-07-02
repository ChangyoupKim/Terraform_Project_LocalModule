variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
}

variable "min_size" {
  description = "ASG Min Size"
  type        = string
}

variable "max_size" {
  description = "ASG Max Size"
  type        = string
}

variable "name" {
  description = "ENV Name(Stage or Prod)"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnets for the ASG"
  type        = list(string)
}

variable "SSH_SG_ID" {
  description = "Security Group ID for SSH access"
  type        = string
}

variable "HTTP_HTTPS_SG_ID" {
  description = "Security Group ID for HTTP/HTTPS access"
  type        = string
}

variable "desired_capacity" {
  description = "Desired capacity of the ASG"
  type        = number
}

variable "target_group_arns" {
  description = "List of target group ARNs for the ASG"
  type        = list(string)
}

# 원하는 용량지정
variable "desired_size" {
  description = "ASG Desired_Capacity"
  type        = string
}