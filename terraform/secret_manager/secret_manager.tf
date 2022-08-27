provider "aws" {
  region = "us-east-1"
}

variable "dl_bucket_id" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_secret_key" {
  type = string
}

resource "aws_secretsmanager_secret" "dl_bucket" {
  name = "AIRFLOW_VAR_DL_BUCKET"
  description = "Bucket arn for the Data Lake"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "dl_bucket_secret" {
  secret_id = aws_secretsmanager_secret.dl_bucket.id
  secret_string = var.dl_bucket_id
}

resource "aws_secretsmanager_secret" "caged_rais_ftp_server" {
  name = "AIRFLOW_CONN_CAGED_RAIS_FTP"
  description = "CAGED/RAIS FTP server"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "caged_rais_ftp_server_secret" {
  secret_id = aws_secretsmanager_secret.caged_rais_ftp_server.id
  secret_string = "ftp://anonymous@ftp.mtps.gov.br"
}

# resource "aws_secretsmanager_secret" "gcp_iam_secret_conn" {
#   name = "AIRFLOW_CONN_GCP_IAM"
#   description = "AIRFLOW GCP CONNECTION"
#   recovery_window_in_days = 0
# }

# resource "aws_secretsmanager_secret_version" "gcp_iam_secret_conn" {
#   secret_id = aws_secretsmanager_secret.gcp_iam_secret_conn.id
#   secret_string = "google-cloud-platform://?extra__google_cloud_platform__keyfile_dict=${jsonencode(var.gcp_secret_key)}" 
# }

# resource "aws_secretsmanager_secret" "gcp_iam_secret" {
#   name = "GCP_SECRET_KEY"
#   description = "GCP SECRET"
#   recovery_window_in_days = 0
# }

# resource "aws_secretsmanager_secret_version" "gcp_iam_secret_value" {
#   secret_id = aws_secretsmanager_secret.gcp_iam_secret.id
#   secret_string = var.gcp_secret_key
# }


resource "aws_secretsmanager_secret" "gcp_project_secret" {
  name = "AIRFLOW_VAR_GCP_PROJECT_ID"
  description = "GCP PROJECT ID"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "gcp_project_secret_value" {
  secret_id = aws_secretsmanager_secret.gcp_project_secret.id
  secret_string = var.gcp_project
}
