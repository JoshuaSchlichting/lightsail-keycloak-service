resource "aws_lightsail_instance" "this" {
  name              = "lightsail-${var.org}-${var.service_name}-${var.env}"
  availability_zone = var.availability_zone
  blueprint_id      = var.blueprint_id
  bundle_id         = var.bundle_id
  user_data         = <<-EOF
#!/bin/bash
# Check "sudo cat /var/log/cloud-init-output.log" for output
su -c "echo 'sudo tail -f /var/log/cloud-init-output.log' >> /home/ec2-user/get-init-log.sh" ec2-user
su -c "chmod +x /home/ec2-user/get-init-log.sh" ec2-user
yum update -y
yes | yum install docker git
curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
curl -LJO https://github.com/joshuaschlichting/create-aws-profile/releases/download/v0.1.1/create-aws-profile_linux_amd64
chmod +x create-aws-profile_linux_amd64
mv create-aws-profile_linux_amd64 /bin/create-aws-profile

mkdir /root/.aws/
cat > /root/.aws/credentials <<-EOFF
[default]
aws_access_key_id = ${var.aws_access_key_id}
aws_secret_access_key = ${var.aws_secret_access_key}
EOFF
cat > /root/.aws/config <<-EOFF
[default]
region=${var.region}
output=json
EOFF
echo export AWS_CONFIG_FILE=/root/.aws/config >> ~/.bashrc
echo export AWS_SHARED_CREDENTIALS_FILE=/root/.aws/credentials >> ~/.bashrc
export AWS_CONFIG_FILE=/root/.aws/config
export AWS_SHARED_CREDENTIALS_FILE=/root/.aws/credentials
export AWS_DEFAULT_REGION=${var.region}
AWS_PROFILE=default aws sts assume-role --role-arn "${var.iam_role}" --role-session-name LightsailSession | create-aws-profile --profile devops --credentials-file /root/.aws/credentials
echo done assuming role ${var.iam_role}
service docker start
usermod -a -G docker ec2-user

source ~/.bashrc

cat > update-cert.sh <<-EOFF
#!/bin/bash
# Updates cert and uploads to S3
mv /etc/letsencrypt /etc/letsencrypt.bak
docker stop traefik
docker run -it --rm --name certbot \
-v "/etc/letsencrypt:/etc/letsencrypt" \
-v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
-p 80:80 \
certbot/certbot certonly \
--standalone \
--preferred-challenges http \
--agree-tos \
--email ${var.lets_encrypt_contact_email_address} \
-d ${var.domain_root}
AWS_PROFILE=devops aws s3 rm --recursive s3://${var.s3_bucket_name}/letsencrypt/${var.domain_root}/
AWS_PROFILE=devops aws s3 cp /etc/letsencrypt s3://${var.s3_bucket_name}/letsencrypt/${var.domain_root} --recursive

EOFF
chmod +x update-cert.sh
AWS_PROFILE=devops aws s3 cp s3://${var.s3_bucket_name}/letsencrypt/${var.domain_root} /etc/letsencrypt --recursive

cat > /traefik_dynamic.toml <<-EOFF
[tls.stores]
  [[tls.certificates]]
    certFile = "/etc/ssl/cert.pem"
    keyFile = "/etc/ssl/privkey.pem"
  [tls.stores.default]
    [tls.stores.default.defaultCertificate]
      certFile = "/etc/ssl/cert.pem"
      keyFile = "/etc/ssl/privkey.pem"
EOFF

cat > docker-compose.yml <<-EOFF
version: "3.9"  # optional since v1.27.0
services:
  traefik:
    image: "traefik:v2.9"
    container_name: "traefik"
    command:
      - "--log.level=DEBUG"
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.file.filename=/traefik_dynamic.toml"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
    ports:
      - "80:80"
      - "8080:8080"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - ./traefik_dynamic.toml:/traefik_dynamic.toml
      - /etc/letsencrypt/live/${var.domain_root}/:/etc/ssl/
  webservice:
    image: quay.io/keycloak/keycloak:${var.keycloak_version}
    restart: always
    container_name: webservice
    environment:
      - KEYCLOAK_ADMIN=admin
      - KEYCLOAK_ADMIN_PASSWORD=${var.keycloak_admin_password}
      - KC_PROXY=edge
      - KC_HOSTNAME_STRICT=false
      - KC_DB=${var.db_type}

      - KC_DB_PORT=${var.db_port}
      - KC_DB_DATABASE=${var.db_name}
      - KC_DB_USERNAME=${var.db_user}
      - KC_DB_PASSWORD=${var.db_password}
      - KC_DB_URL=jdbc:${var.db_type}://${var.db_address}:${var.db_port}/${var.db_name}

      # cockroach
      # - KC_DB_SSL_MODE=verify-full
      # - KC_DB_URL=
      # - KC_DB_DATABASE=
      # - KC_DB_USERNAME=
      # - KC_DB_PORT=
      # - KC_DB_PASSWORD=
     
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.webservice.rule=Host(\`${var.domain_root}\`)"
      - "traefik.http.routers.webservice.entrypoints=websecure"
      - "traefik.http.routers.webservice.tls=true"

    command: start
EOFF
${var.pre_service_start_script}
docker-compose up -d
echo done starting web services
echo INFO: The Keycloak service will take a moment to start. Check to see if it has finished using 'docker logs -f webservice'
EOF
}

resource "aws_lightsail_instance_public_ports" "this" {
  instance_name = aws_lightsail_instance.this.name
  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
  }
  port_info {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
  }
  port_info {
    protocol  = "tcp"
    from_port = 8080
    to_port   = 8080
  }
  port_info {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
  }
}

resource "aws_lightsail_static_ip_attachment" "this" {
  static_ip_name = var.static_ip_name
  instance_name  = aws_lightsail_instance.this.id
}




