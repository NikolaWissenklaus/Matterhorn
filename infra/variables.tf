# Projeto e região

variable "project_id" {
  description = "ID do projeto no Google Cloud onde tudo será criado."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Use o ID do projeto (ex.: meu-projeto-123), não o nome nem o número."
  }
}

variable "region" {
  description = "Região do Cloud Run e do repositório no Artifact Registry."
  type        = string
  default     = "us-central1"
}

# BigQuery

variable "bigquery_location" {
  description = "Localização do dataset (US, EU ou uma região, como southamerica-east1). Não muda depois de criado."
  type        = string
  default     = "US"
}

variable "dataset_id" {
  description = "ID do dataset que recebe os eventos."
  type        = string
  default     = "matterhorn_dataset"

  validation {
    condition     = can(regex("^[A-Za-z0-9_]+$", var.dataset_id))
    error_message = "O ID do dataset aceita apenas letras, números e sublinhado."
  }
}

variable "dataset_friendly_name" {
  description = "Nome de exibição do dataset no console."
  type        = string
  default     = "Matterhorn Events"
}

variable "dataset_description" {
  description = "Descrição do dataset no console."
  type        = string
  default     = "Dataset para os eventos Web"
}

variable "table_id" {
  description = "ID da tabela de eventos brutos."
  type        = string
  default     = "events_raw"
}

# Cloud Run

variable "service_name" {
  description = "Nome do serviço no Cloud Run. Faz parte da URL gerada."
  type        = string
  default     = "matterhorn-backend"
}

variable "service_account_id" {
  description = "ID da service account usada pelo Cloud Run (6 a 30 caracteres)."
  type        = string
  default     = "matterhorn-cr-sa"
}

variable "service_account_display_name" {
  description = "Nome de exibição da service account."
  type        = string
  default     = "Cloud Run - Ingestão BigQuery"
}

variable "artifact_repository" {
  description = "Repositório Docker no Artifact Registry, na mesma região do serviço."
  type        = string
  default     = "matterhorn-repo"
}

variable "image_name" {
  description = "Nome da imagem gerada pelo Cloud Build."
  type        = string
  default     = "matterhorn-api"
}

variable "image_tag" {
  description = "Tag da imagem em produção (ex.: v7). Troque aqui a cada deploy; um gcloud run deploy fora do Terraform é revertido no próximo apply."
  type        = string
}

variable "max_instance_count" {
  description = "Máximo de instâncias simultâneas. Serve também como teto de custo."
  type        = number
  default     = 3

  validation {
    condition     = var.max_instance_count >= 1
    error_message = "max_instance_count precisa ser pelo menos 1."
  }
}

variable "cpu" {
  description = "CPU por instância, no formato do Cloud Run (\"1\", \"2\", \"4\")."
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memória por instância, no formato do Cloud Run (\"512Mi\", \"1Gi\")."
  type        = string
  default     = "512Mi"
}
