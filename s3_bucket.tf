resource "aws_s3_bucket" "tfe_fdo_s3_bucket" {
  bucket = var.object_storage_s3_bucket
  force_destroy = true
  tags = {
    Name        = "TFE FDO S3 Bucket"
    Environment = "Dev"
  }
}

