# Lightsail Keycloak Service (Terraform Module)
This repository is a terraform module that creates an AWS Lightsail Instance which hosts an instance of Red Hat's Keycloak authentication service behind a Traefik reverse proxy.

# BEFORE GETTING STARTED
This module requires a Let's Encrypt payload to be stored in an S3 bucket with the following prefix: `letsencrypt/example.com`
This can be easily done as a one-time requirement by manually SSH'ing into the Lightsail instance and adhering to the following steps:
  1. Execute the `/update-cert.sh` script in located at `/`
  1. Follow the Let's Encrypt prompts
  1. Destroy and recreate the module hosting the instance.
> *Why do this instead of the usual Let's Encrypt automation?*
> 
> This route avoids hitting the rate limits for the Let's Encrypt servers, enabling you to destroy and recreate this instance as often as needed.

[See the `params.tf` file for parameters.](params.tf)


## Example usage
```terraform
module "keycloak_server" {
  source                             = "./modules/lightsail_keycloak_service"
  org                                = "exampleorg"
  env                                = "test"
  service_name                       = "keycloak"
  availability_zone                  = "us-east-1a"
  blueprint_id                       = "amazon_linux_2"
  bundle_id                          = "micro_2_0"
  aws_access_key_id                  = "XXXXX"
  aws_secret_access_key              = "XXXXX"
  iam_role                           = "role ARN"
  region                             = "us-east-1"
  domain_root                        = "auth.example.com"
  s3_bucket_name                     = "example_bucket"
  static_ip_name                     = "lightsail-static-ip-resource-name-goes-here"
  pre_service_start_script           = "" # additional code to execute before services start
  keycloak_version                   = "latest"
  keycloak_admin_password            = "super secure password"
  lets_encrypt_contact_email_address = "example@example.com"
  db_type                            = "postgres"
  db_url                             = "jdbc:postgresql://0.0.0.0:5432/keycloak"
  db_username                        = "keycloak"
  db_password                        = "super secure password"
  db_port                            = "5432"
  db_address                         = "example.com"
}
```
