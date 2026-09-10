locals {
  # Imagem publicada pelo Cloud Build. O repositório fica na mesma região do
  # serviço.
  container_image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_repository}/${var.image_name}:${var.image_tag}"
}

resource "google_cloud_run_v2_service" "matterhorn_backend" {
  name     = var.service_name
  location = var.region

  # Os eventos chegam direto do navegador dos visitantes, então o serviço
  # precisa aceitar tráfego da internet.
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email

    # Além de escalar, o teto limita o custo se alguém disparar eventos em
    # massa contra o endpoint público.
    scaling {
      max_instance_count = var.max_instance_count
    }

    containers {
      image = local.container_image

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      # Destino dos inserts no app.py. Os valores saem dos próprios recursos
      # para o código e a infraestrutura nunca apontarem para lugares
      # diferentes.
      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }
      env {
        name  = "DATASET_ID"
        value = google_bigquery_dataset.matterhorn_dataset.dataset_id
      }
      env {
        name  = "TABLE_ID"
        value = google_bigquery_table.events_table.table_id
      }
    }
  }

  # Um gcloud run deploy grava no serviço o nome e a versão do cliente.
  # Sem isto, todo plan feito depois de um deploy manual acusaria diferença.
  lifecycle {
    ignore_changes = [client, client_version]
  }
}

# Invocação sem autenticação: é o que deixa qualquer navegador enviar
# eventos. Em troca, qualquer pessoa com a URL também consegue.
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = google_cloud_run_v2_service.matterhorn_backend.project
  location = google_cloud_run_v2_service.matterhorn_backend.location
  name     = google_cloud_run_v2_service.matterhorn_backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
