# As credenciais vêm do Application Default Credentials
# (gcloud auth application-default login).
provider "google" {
  project = var.project_id
  region  = var.region
}
