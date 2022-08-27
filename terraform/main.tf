provider "aws" {
  region = "us-east-1"
}
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  tags = {
    Author = "Terraform"
  }
}

variable "airflow_dags_bucket_name" {
  type    = string
  default = "vplentz-airflow-dags"
}
variable "prefix" {
  type = string
}
variable "mwaa_max_workers" {
  type = number
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "dl_bucket_name" {
  type = string
}

module "dl_gcs" {
  source            = "./dl_gcs"
  dl_gcs_bucket_name = var.dl_bucket_name
}

module "s3_dags" {
  source = "./s3_dags"
  airflow_dags_bucket_name = var.airflow_dags_bucket_name
}

module "mwaa_network" {
  source               = "./network"
  prefix               = var.prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "secret_manager" {
  source = "./secret_manager"
  dl_bucket_id = module.dl_gcs.dl_bucket_id
  gcp_secret_key = module.dl_gcs.service_credential_private
  gcp_project = "caged-rais-vplentz"
}


resource "aws_iam_role" "iam_role" {
  name = var.prefix
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "mwaa"
        Principal = {
          Service = [
            "airflow-env.amazonaws.com",
            "airflow.amazonaws.com"
          ]
        }
      },
    ]
  })

  tags = {
    Name = var.prefix
  }
}

data "aws_iam_policy_document" "iam_policy_document" {
  statement {
    sid       = ""
    actions   = ["airflow:PublishMetrics"]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid       = ""
    actions   = ["s3:ListAllMyBuckets"]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = ""
    actions = [
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:List*"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid       = ""
    actions   = ["logs:DescribeLogGroups"]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = ""
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:GetLogRecord",
      "logs:GetLogGroupFields",
      "logs:GetQueryResults",
      "logs:DescribeLogGroups"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid       = ""
    actions   = ["cloudwatch:PutMetricData"]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = ""
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = ""
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = ""
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt"
    ]
    effect        = "Allow"
    not_resources = ["arn:aws:kms:*:${local.account_id}:key/*"]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values = [
        "sqs.us-east-1.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "iam_policy" {
  name   = var.prefix
  path   = "/"
  policy = data.aws_iam_policy_document.iam_policy_document.json
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment" {
  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.iam_policy.arn
}


resource "aws_mwaa_environment" "airflow" {
  name                  = var.prefix
  airflow_version       = "2.2.2"
  dag_s3_path           = "dags/"
  requirements_s3_path = "requirements.txt"
  requirements_s3_object_version = module.s3_dags.requirements_version_id
  environment_class     = "mw1.small"
  execution_role_arn    = aws_iam_role.iam_role.arn
  max_workers           = var.mwaa_max_workers
  source_bucket_arn     = module.s3_dags.dag_bucket_arn
  webserver_access_mode = "PUBLIC_ONLY"
  depends_on = [
    module.s3_dags
  ]
  network_configuration {
    security_group_ids = [module.mwaa_network.aws_sg_id]
    subnet_ids         = module.mwaa_network.private_subnets_ids
  }
  airflow_configuration_options = {
    "secrets.backend" = "airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend",
    "secrets.backend_kwargs" = jsonencode({"connections_prefix" : "AIRFLOW_CONN", "variables_prefix" : "AIRFLOW_VAR", "sep" : "_"})
  }
}

output "AirflowIP" {
  value = aws_mwaa_environment.airflow.webserver_url
}

output "service_credential_private"{
  value = module.dl_gcs.service_credential_private
}