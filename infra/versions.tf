terraform {
  required_version = ">= 1.5"

  required_providers {
    # Travado na série 5.x. A 6.x traz mudanças incompatíveis em recursos
    # usados aqui; antes de subir, leia o guia de upgrade do provider e
    # confira o plan com atenção.
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
