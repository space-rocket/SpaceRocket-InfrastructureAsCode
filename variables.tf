variable "region" {
  type    = string
  default = "us-west-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.123.0.0/16"
}

variable "access_ip" {
  type    = string
  default = "0.0.0.0/0"
}

variable "cloud9_ip" {
  type    = string
  default = "54.177.171.4/32"
}

variable "public_cidrs" {
  type    = list(string)
  default = ["10.123.1.0/24", "10.123.3.0/24"]
}

variable "private_cidrs" {
  type    = list(string)
  default = ["10.123.2.0/24", "10.123.4.0/24"]
}

variable "main_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "main_vol_size" {
  type    = number
  default = 8
}

variable "main_instance_count" {
  type    = number
  default = 1
}

variable "key_name" {
  type = string
}

variable "public_key_path" {
  type = string
}
variable "private_key_path" {
  type = string
}

variable "main_domain_name" {
  type = string
}

variable "db_name" {
  description = "RDS database name"
  default     = "default_db_name"
}

variable "db_user" {
  description = "RDS root username"
  # sensitive   = true
  default = "default_db_user"
}

variable "db_password" {
  description = "RDS root user password"
  type        = string
  sensitive   = true
}

variable "git_url" {
  type        = string
  description = "Github repo ex: Spoon-Knife"
  default     = "https://github.com/space-rocket/my_app.git"
}

variable "has_db" {
  type        = bool
  description = "Does your app use a DB?"
  default     = false
}

variable "deploy_demo_docker" {
  type        = bool
  description = "Deploy demo Docker app?"
  default     = false
}

variable "deploy_my_app" {
  type        = bool
  description = "Deploy Elixir Phoenix application called my_app?"
  default     = false
}




