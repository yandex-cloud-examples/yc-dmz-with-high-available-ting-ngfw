terraform {
  required_version = ">= 0.14"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.138.0"
    }

    null = {
      source = "hashicorp/null"
      version = "~> 3.2.1"
    }
  }
}
