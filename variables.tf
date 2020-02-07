variable "company" {
  type = string
}

variable "owner" {
  description = "Owner of the resource. This variable is used to set the 'owner' label. Will be used as default for each bucket, but can be overridden using the bucket settings"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment for which the resources are created (e.g. dev, tst, acc or prd)"
  type        = string
}

variable "buckets_force_destroy" {
  description = "When set to true, allows TFE to remove buckets that still contain objects"
  type        = bool
  default     = false
}

variable "buckets" {
  description = "Map of buckets to be created. The key will be used for the bucket name so it should describe the bucket purpose. The value can be a map with bucket setting objects. Refer to the bucket_defaults variable to see the object definition."
  type        = map(any)
}

variable "bucket_defaults" {
  description = "Default settings to be used for your buckets so you don't need to provide them for each bucket separately."
  type = object({

    force_destroy         = bool
    acceleration_status   = string
    region                = string
    acl                   = string
    kms_encryption_key_id = string

    website = object({
      index_document           = string
      error_document           = string
      redirect_all_requests_to = string
      routing_rules            = string
    })

    cors_rule = object({
      allowed_methods = list(string)
      allowed_origins = list(string)
      allowed_headers = list(string)
      expose_headers  = list(string)
      max_age_seconds = number
    })

    versioning = object({
      enabled    = bool
      mfa_delete = bool
    })

    logging = object({
      target_bucket = string
      target_prefix = string
    })

    lifecycle_rules = map(object({
      enabled                                = bool
      id                                     = string
      prefix                                 = string
      tags                                   = list(string)
      abort_incomplete_multipart_upload_days = number

      expiration = object({
        date                         = string
        days                         = number
        expired_object_delete_marker = bool
      })

      noncurrent_version_expiration = object({
        days = number
      })

      noncurrent_version_transition = map(object({
        days          = number
        storage_class = string
      }))

      transition = map(object({
        date          = string
        days          = number
        storage_class = string
      }))
    }))

    replication_configuration = object({
      role = string
      rules = map(object({
        id       = string
        priority = number
        status   = string

        destination = object({
          bucket             = string
          storage_class      = string
          replica_kms_key_id = string
          account_id         = string
          access_control_translation = object({
            owner = string
          })
        })

        source_selection_criteria = object({
          sse_kms_encrypted_objects = object({
            enabled = bool
          })
        })

        filter = object({
          prefix = string
          tags   = list(string)
        })
      }))
    })

    object_lock_configuration = object({
      object_lock_enabled = bool
      rule = object({
        default_retention = object({
          mode  = string
          days  = number
          years = number
        })
      })
    })
    roles = map(list(string))
  })

  default = {
    force_destroy         = false
    acceleration_status   = null
    region                = "eu-west-1"
    acl                   = null
    kms_encryption_key_id = null

    website                   = null
    cors_rule                 = null
    versioning                = null
    logging                   = null
    lifecycle_rules           = {}
    replication_configuration = null
    object_lock_configuration = null
    roles                     = {}
  }
}
