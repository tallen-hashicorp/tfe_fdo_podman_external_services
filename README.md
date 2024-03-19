# Terraform Enterprise installation external services - Work In Progress!!!

This repo was forked from the great example [tfe_fdo_podman_disk](https://github.com/munnep/tfe_fdo_podman_disk) created by [Patrick Munne](https://github.com/munnep)

With this repository you will be able to do a TFE FDO (Terraform Enterprise) online installation Mounted Disk with Podman for the container management. The data will be stored to mount point `/opt/tfe/data`

The Terraform code will do the following steps

- Create S3 buckets used for TFE to store certificates
- Generate TLS certificates with Let's Encrypt to be used by TFE
- Create a VPC network with subnet, security group, internet gateway
- Create a EC2 instance on which the TFE installation will be performed in mounted disk mode
- Setup PostgresDB on the Server and configure it ready for TFE to use

# Diagram

![](diagram/diagram-tfe_external_disk.png)  

# Using a proxy server
Use a proxy server with this TFE following these steps described [here](proxy-server.md) after everything is build

# Prerequisites

## AWS
We will be using AWS. Make sure you have the following
- AWS account  
- Install AWS cli [See documentation](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- An AWS Bucket with a seperate AWS Key and Secret with access to the bucket

## Install terraform  
See the following documentation [How to install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

## TLS certificate
You need to have valid TLS certificates that can be used with the DNS name you will be using to contact the TFE instance.  
  
The repo assumes you have no certificates and want to create them using Let's Encrypt and that your DNS domain is managed under AWS. 

# How to

- Clone the repository to your local machine
```
git clone https://github.com/munnep/tfe_fdo_podman_disk.git
```
- Go to the directory
```
cd tfe_fdo_podman_disk
```
- Set your AWS credentials
```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=
```
- create a file called `variables.auto.tfvars` with the following contents and your own values
```
tag_prefix                              = "tfe32"                         # TAG prefix for names to easily find your AWS resources
region                                  = "eu-north-1"                    # Region to create the environment
vpc_cidr                                = "10.231.0.0/16"                 # subnet mask that can be used   
dns_hostname                            = "tfe32"                         # DNS hostname for the TFE
dns_zonename                            = "aws.tallen.com"                # DNS zone name to be used
tfe_password                            = "Password#1"                    # TFE password for the dashboard and encryption of the data
certificate_email                       = "tyler.allen@hashicorp.com"     # Your email address used by TLS certificate registration
public_key                              = "ssh-rsa AAAAB3Nza"             # The public key for you to connect to the server over SSH
tfe_release                             = "v202402-1"                     # Version number for the release to install. This must have a value
tfe_license                             = "<very_secret>"                 # license file being used
terraform_client_version                = "1.1.7"                         # Terraform CLI version installed on the client machine
object_storage_key_id                   = "your_key_id"                   # A AWS Key ID for the object bucket
object_storage_access_key               = "your_access_key"               # A AWS Key for the object bucket
object_storage_s3_bucket                = "your_s3_bucket_name"           # A AWS S3 Bucket for the object storage
object_storage_s3_bucket_re gion        = "eu-north-1"                    # The Region of the bucket
```
- Terraform initialize
```
terraform init
```
- Terraform plan
```
terraform plan
```
- Terraform apply
```
terraform apply
```
- Terraform output should create 34 resources and show you the public dns string you can use to connect to the TFE instance
```
Apply complete! Resources: 34 added, 0 changed, 0 destroyed.

Outputs:

private_ip = "10.115.1.23"
ssh_tf_client = "ssh ubuntu@tfe32-client.aws.munnep.com"
ssh_tfe_server = "ssh ec2-user@tfe32.aws.munnep.com"
tfe_appplication = "https://tfe32.aws.munnep.com"
tfe_ip = "ssh ubuntu@52.212.76.15"
```
- **Wait about 10-15 minites** for eveything to be setup
- You can now login to the application with the username `admin` and password specified in your variables.

# notes and links
[EC2 AWS bucket access](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-instance-access-s3-bucket/)

# Example TFE manifest
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
          - name: "TFE_OBJECT_STORAGE_S3_SECRET_ACCESS_KEY"
            value: "${object_storage_access_key}"
          - name: "TFE_OBJECT_STORAGE_TYPE"
            value: "s3"
          - name: "TFE_OBJECT_STORAGE_S3_BUCKET"
            value: "${object_storage_s3_bucket}"
          - name: "TFE_OBJECT_STORAGE_S3_REGION"
            value: "${object_storage_s3_bucket_region}"
          image: "images.releases.hashicorp.com/hashicorp/terraform-enterprise:v202312-1"
          name: "terraform-enterprise"
          ports:
          - containerPort: 8080
            hostPort: 80
          - containerPort: 8443
            hostPort: 443
          - containerPort: 9090
            hostPort: 9090
          securityContext:
            capabilities:
              add:
              - "CAP_IPC_LOCK"
            readOnlyRootFilesystem: true
            seLinuxOptions:
              type: "spc_t"
          volumeMounts:
          - mountPath: "/etc/ssl/private/terraform-enterprise"
            name: "certs"
          - mountPath: "/var/log/terraform-enterprise"
            name: "log"
          - mountPath: "/run"
            name: "run"
          - mountPath: "/tmp"
            name: "tmp"
          - mountPath: "/var/lib/terraform-enterprise"
            name: "data"
          - mountPath: "/run/docker.sock"
            name: "docker-sock"
          - mountPath: "/var/cache/tfe-task-worker/terraform"
            name: "terraform-enterprise_terraform-enterprise-cache-pvc"
        volumes:
        - hostPath:
            path: "/opt/tfe/certs"
            type: "Directory"
          name: "certs"
        - emptyDir:
            medium: "Memory"
          name: "log"
        - emptyDir:
            medium: "Memory"
          name: "run"
        - emptyDir:
            medium: "Memory"
          name: "tmp"
        - hostPath:
            path: "/opt/tfe/data"
            type: "Directory"
          name: "data"
        - hostPath:
            path: "/var/run/docker.sock"
            type: "File"
          name: "docker-sock"
        - name: "terraform-enterprise_terraform-enterprise-cache-pvc"
          persistentVolumeClaim:
            claimName: "terraform-enterprise_terraform-enterprise-cache"
```