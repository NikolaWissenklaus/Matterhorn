# Identidade do serviço no Cloud Run. Sem ela o container rodaria com a conta
# padrão do Compute Engine, que costuma ter permissões demais.
resource "google_service_account" "cloud_run_sa" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
}

# Permite que o serviço insira linhas no BigQuery.
#
# O papel vale para o projeto todo. Para limitar ao dataset do Matterhorn,
# troque por google_bigquery_dataset_iam_member.
resource "google_project_iam_member" "bq_data_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = google_service_account.cloud_run_sa.member
}
