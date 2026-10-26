terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # First apply ran with local state (the bucket didn't exist yet); state was then moved here
  # with `terraform init -migrate-state`.
  backend "s3" {
    bucket       = "aws-portfolio-tfstate-786742959962"
    key          = "aws-portfolio-bootstrap/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      project    = "aws-portfolio"
      repo       = "aws-portfolio-bootstrap"
      owner      = "praveen"
      managed-by = "terraform"
    }
  }
}
