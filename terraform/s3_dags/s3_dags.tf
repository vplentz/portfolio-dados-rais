provider "aws" {
  region = "us-east-1"
}

variable "airflow_dags_bucket_name" {
  type = string
}


resource "aws_s3_bucket" "dags_bucket" {
  bucket_prefix = var.airflow_dags_bucket_name
  force_destroy = true
  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.dags_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "upload_dags" {
  for_each = fileset("dags/", "*.py")
  bucket   = aws_s3_bucket.dags_bucket.id
  key      = "dags/${each.value}"
  source   = "dags/${each.value}"
}


resource "aws_s3_bucket_object" "upload_requirements" {
  bucket   = aws_s3_bucket.dags_bucket.id
  key      = "requirements.txt"
  source   = "dags/requirements.txt"
}


output "dag_bucket_arn" {
  value = aws_s3_bucket.dags_bucket.arn
}

output "requirements_version_id"{
    value = aws_s3_bucket_object.upload_requirements.version_id
}