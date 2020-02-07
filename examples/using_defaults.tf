locals {
  company     = "company"
  owner       = "myself"
  environment = "dev"
  project     = "testapp"

  buckets = {
    "functions" = {
    }
    "processed" = {
    }
  }
}

module "buckets" {
  source  = "binxio/s3-bucket/aws"
  version = "~> 1.0.0"

  company     = local.company
  owner       = local.owner
  environment = local.environment
  project     = local.project

  buckets = local.buckets
}
