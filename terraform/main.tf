terraform {
  cloud {
    organization = "sp-howard"

    workspaces {
      name = "wordpress-multi-tier"
    }
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}