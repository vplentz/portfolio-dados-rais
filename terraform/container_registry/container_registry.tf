provider "google-beta" {
  region = "us-east1"
}

variable "gcp_project_id" {
  type=string
  default = "caged-rais-vplentz"
}

resource "google_artifact_registry_repository" "google-caged-docker-repo" {
  provider = google-beta
  location      = "us-east1"
  project = var.gcp_project_id
  repository_id = "caged-rais-docker-repo"
  description   = "Docker Image Repo for CAGED-RAIS Project"
  format        = "DOCKER"
}

output "gce_id" {
  value=google_artifact_registry_repository.google-caged-docker-repo.id
}