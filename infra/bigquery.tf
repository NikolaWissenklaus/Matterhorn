resource "google_bigquery_dataset" "matterhorn_dataset" {
  dataset_id    = var.dataset_id
  friendly_name = var.dataset_friendly_name
  description   = var.dataset_description
  location      = var.bigquery_location
}

# Um evento por linha. O esquema imita o export do GA4: event_params é um
# RECORD REPEATED de pares chave/valor, então as consultas com UNNEST que
# funcionam lá funcionam aqui.
#
# Colunas novas (NULLABLE) entram com um apply comum. Remover coluna ou mudar
# tipo obriga o Terraform a recriar a tabela, e o deletion_protection (ligado
# por padrão no provider) barra isso para não apagar dados por engano.
resource "google_bigquery_table" "events_table" {
  dataset_id = google_bigquery_dataset.matterhorn_dataset.dataset_id
  table_id   = var.table_id
  schema     = file("${path.module}/schemas/events_raw.json")
}
