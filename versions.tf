terraform {
  required_version = ">= 1.5"
  required_providers {
    aws   = { source = "hashicorp/aws", version = "~> 5.0" }   # provider #1: ha tang
    tls   = { source = "hashicorp/tls", version = "~> 4.0" }   # provider #2: sinh SSH key
    local = { source = "hashicorp/local", version = "~> 2.0" } # provider #3: ghi .pem ra dia
  }
}

provider "aws" {
  region = var.region
  # Khong set profile -> dung AWS credential chain chuan:
  #   env AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY, hoac AWS_PROFILE, hoac default profile (~/.aws/credentials)
  default_tags {
    tags = {
      Project   = "w8-challenge"
      ManagedBy = "terraform"
    }
  }
}
