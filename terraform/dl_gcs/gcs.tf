provider "google" {
  region="us-east1"
}

variable "gcp_project" {
  type = string
  default = "caged-rais-vplentz"
}

variable "dl_gcs_bucket_name" {
  type = string
  default = "vplentz-dl-dev"
}

resource "google_storage_bucket" "dl_bucket" {
  name = var.dl_gcs_bucket_name
  project = var.gcp_project
  location = "US"
  force_destroy = true
}

resource "google_service_account" "gcs_service_account" {
  account_id   = "gcs-service-account"
  project = var.gcp_project
  display_name = "A service account to interact with GCS DL bucket."
}

resource "google_storage_bucket_iam_binding" "gcs-iam-binding" {
  bucket = var.dl_gcs_bucket_name
  role = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.gcs_service_account.email}",
  ]
}


resource "google_project_iam_binding" "gke_permissions" {
  project = "caged-rais-vplentz"
  role    = "roles/container.admin"

  members = [
    "serviceAccount:${google_service_account.gcs_service_account.email}",
  ]
}

resource "google_project_iam_binding" "user_iam_permissions" {
  project = "caged-rais-vplentz"
  role    = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:${google_service_account.gcs_service_account.email}",
  ]
}

resource "google_service_account_key" "service-account-credentials" {
  service_account_id = google_service_account.gcs_service_account.name
}

output "service_credential_pub" {
  value = google_service_account_key.service-account-credentials.public_key
}

output "service_credential_private" {
  value = base64decode(google_service_account_key.service-account-credentials.private_key)
  sensitive = true
}

output "dl_bucket_id" {
  value = google_storage_bucket.dl_bucket.id
}