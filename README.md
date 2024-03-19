# Terraform Enterprise Installation External Services - Work in Progress!!!

This repository was forked from the great example [tfe_fdo_podman_disk](https://github.com/munnep/tfe_fdo_podman_disk) created by [Patrick Munne](https://github.com/munnep).

With this repository, you will be able to perform a TFE FDO (Terraform Enterprise) online installation Mounted Disk with Podman for container management. The data will be stored in the mount point `/opt/tfe/data`.

The Terraform code will perform the following steps:

- Create S3 buckets used for TFE to store certificates.
- Generate TLS certificates with Let's Encrypt to be used by TFE.
- Create a VPC network with subnet, security group, and internet gateway.
- Create an EC2 instance on which the TFE installation will be performed in mounted disk mode.
- Set up PostgresDB on the server and configure it ready for TFE to use.

## Using a Proxy Server
Use a proxy server with this TFE following these steps described [here](proxy-server.md) after everything is built.

## Prerequisites

### AWS
We will be using AWS. Make sure you have the following:
- AWS account  
- Install AWS CLI [See documentation](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- An AWS Bucket with a separate AWS Key and Secret with access to the bucket

### Install Terraform  
See the following documentation [How to install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

### TLS Certificate
You need to have valid TLS certificates that can be used with the DNS name you will be using to contact the TFE instance.  
  
The repository assumes you have no certificates and want to create them using Let's Encrypt and that your DNS domain is managed under AWS. 

## How to

- Clone the repository to your local machine
```sh
git clone https://github.com/munnep/tfe_fdo_podman_disk.git
```
- Go to the directory
```sh
cd tfe_fdo_podman_disk
```
- Set your AWS credentials
```sh
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=
```
- Create a file called `variables.auto.tfvars` with the following contents and your own values
```hcl
tag_prefix                              = "tfe32"                         # TAG prefix for names to easily find your AWS resources
region                                  = "eu-north-1"                    # Region to create the environment
vpc_cidr                                = "10.231.0.0/16"                 # Subnet mask that can be used   
dns_hostname                            = "tfe32"                         # DNS hostname for the TFE
dns_zonename                            = "aws.tallen.com"                # DNS zone name to be used
tfe_password                            = "Password#1"                    # TFE password for the dashboard and encryption of the data
certificate_email                       = "tyler.allen@hashicorp.com"     # Your email address used by TLS certificate registration
public_key                              = "ssh-rsa AAAAB3Nza"             # The public key for you to connect to the server over SSH
tfe_release                             = "v202402-1"                     # Version number for the release to install. This must have a value
tfe_license                             = "<very_secret>"                 # License file being used
terraform_client_version                = "1.1.7"                         # Terraform CLI version installed on the client machine
object_storage_key_id                   = "your_key_id"                   # An AWS Key ID for the object bucket
object_storage_access_key               = "your_access_key"               # An AWS Key for the object bucket
object_storage_s3_bucket                = "your_s3_bucket_name"           # An AWS S3 Bucket for the object storage
object_storage_s3_bucket_region         = "eu-north-1"                    # The Region of the bucket
```

- Terraform initialize
```sh
terraform init
```
- Terraform plan
```sh
terraform plan
```
- Terraform apply
```sh
terraform apply
```
- Terraform output should create 34 resources and show you the public DNS string you can use to connect to the TFE instance
```sh
Apply complete! Resources: 34 added, 0 changed, 0 destroyed.

Outputs:

private_ip = "10.115.1.23"
ssh_tf_client = "ssh ubuntu@tfe32-client.aws.munnep.com"
ssh_tfe_server = "ssh ec2-user@tfe32.aws.munnep.com"
tfe_application = "https://tfe32.aws.munnep.com"
tfe_ip = "ssh ubuntu@52.212.76.15"
```
- **Wait about 10-15 minutes** for everything to be set up.
- You can now log in to the application with the username `admin` and the password specified in your variables.

## Notes and Links
[EC2 AWS bucket access](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-instance-access-s3-bucket/)

### Example TFE Manifest
```yaml
apiVersion: "v1"
kind: "Pod"
metadata:
  labels:
    app: "terraform-enterprise"
  name: "terraform-enterprise"
spec:
  restartPolicy: "Never"
  containers:
  - env:
    - name: "TFE_OPERATIONAL_MODE"
      value: "external"
    - name: "TFE_LICENSE"
      value: "${tfe_license}"
    - name: "TFE_HTTP_PORT"
      value: "8080"
    - name: "TFE_HTTPS_PORT"
      value: "8443"
    - name: "TFE_HOSTNAME"
      value: "${dns_hostname}.${dns_zonename}"
    - name: "TFE_TLS_CERT_FILE"
      value: "/etc/ssl/private/terraform-enterprise/cert.pem"
    - name: "TFE_TLS_KEY_FILE"
      value: "/etc/ssl/private/terraform-enterprise/key.pem"
    - name: "TFE_TLS_CA_BUNDLE_FILE"
      value: "/etc/ssl/private/terraform-enterprise/bundle.pem"
    - name: "TFE_DISK_CACHE_VOLUME_NAME"
      value: "terraform-enterprise_terraform-enterprise-cache"
    - name: "TFE_LICENSE_REPORTING_OPT_OUT"
      value: "true"
    - name: "TFE_ENCRYPTION_PASSWORD"
      value: "Password#1"
    - name: "TFE_DATABASE_HOST"
      value: "${db_host}"
    - name: "TFE_DATABASE_NAME"
      value: "tfe_admin"
    - name: "TFE_DATABASE_USER"
      value: "tfe_admin"
    - name: "TFE_DATABASE_PASSWORD"
      value: "**********"
    - name: "TFE_DATABASE_PARAMETERS"
      value: "sslmode=disable"
    - name: "TFE_OBJECT_STORAGE_S3_ACCESS_KEY_ID"
      value: "${object_storage_key_id}"
    - name: "TFE_OBJECT_STORAGE_S3
```