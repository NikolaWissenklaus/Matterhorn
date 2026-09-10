output "cloud_run_url" {
  description = "URL base do serviço no Cloud Run."
  value       = google_cloud_run_v2_service.matterhorn_backend.uri
}

output "collector_endpoint" {
  description = "Endereço de coleta. É o valor do ENDPOINT em tracker/matterhorn.js."
  value       = "${google_cloud_run_v2_service.matterhorn_backend.uri}/mhc"
}

output "events_table" {
  description = "Tabela de eventos no formato projeto.dataset.tabela, pronta para usar no FROM."
  value       = "${var.project_id}.${google_bigquery_dataset.matterhorn_dataset.dataset_id}.${google_bigquery_table.events_table.table_id}"
}

output "service_account_email" {
  description = "Service account com que o Cloud Run grava no BigQuery."
  value       = google_service_account.cloud_run_sa.email
}
