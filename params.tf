variable "env" {
  description = "Environment value (e.g. dev, test, prod)"
  type        = string
}

variable "service_name" {
  type = string
}

variable "org" {
  description = "Organization code (e.g. org1, org2)"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone (e.g. us-east-1a)"
  type        = string
}

variable "blueprint_id" {
  description = "Blueprint ID (e.g. ubuntu_18_04)"
  type        = string
}

variable "bundle_id" {
  description = "Bundle ID (e.g. nano_2_0, micro_2_0, medium_2_0, large_2_0)"
  type        = string
}

variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
}

variable "region" {
  description = "AWS region (e.g. us-east-1)"
  type        = string
}

variable "domain_root" {
  description = "Domain root (e.g. myapp.com without any leading prefix)"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of S3 bucket containing 'letsencrypt/domain_root.com' folder"
  type        = string
}

variable "static_ip_name" {
  description = "Name of AWS lightsail static IP address"
  type        = string
}

variable "pre_service_start_script" {
  description = "Script to run before `docker-compose up`"
  type        = string
}

variable "keycloak_version" {
  description = "Keycloak version"
  type        = string
}

variable "keycloak_admin_password" {
  description = "Password for Keycloak admin user"
  type        = string
}

variable "iam_role" {
  description = "IAM role for Keycloak"
  type        = string
}
variable "lets_encrypt_contact_email_address" {
  description = "Email address for Let's Encrypt contact"
  type        = string
}

# Keycloak db config
variable "db_address" {
  description = "Database address"
  type        = string
}
variable "db_port" {
  description = "Database port"
  type        = string
}
variable "db_username" {
  description = "Database username"
  type        = string
}
variable "db_password" {
  description = "Database password"
  type        = string
}
variable "db_url" {
  description = "Database URL"
  type        = string
}
variable "db_type" {
  description = "Database type"
  type        = string
  default     = "postgres"
}