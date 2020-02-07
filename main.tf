#---------------------------------------------------------------------------------------------
# Define our locals for increased readability
#---------------------------------------------------------------------------------------------

locals {
  project     = var.project
  environment = var.environment
  company     = var.company

  bucket_defaults = merge(var.bucket_defaults, {
    owner       = var.owner,
    bucket_name = null # Invalid name, but make sure the key exists
  })

  tags = {
    "${local.company}:environment" = local.environment
    "${local.company}:project"     = local.project
    "${local.company}:created-by"  = "terraform"
  }

  # Merge bucket global default settings with bucket specific settings and generate bucket_name
  # Example generated bucket_name: "company-data-dev-processed"
  buckets = {
    for bucket, settings in var.buckets : bucket => merge(local.bucket_defaults, settings, { bucket_name = lower(format("%s-%s-%s-%s", local.company, local.project, local.environment, replace(bucket, " ", "-"))) })
  }

  # Terraform assertion hack
  assert_head = "\n\n\n!!!!!!!!!!!!!!!!!!!!!! ASSERTION FAILED !!!!!!!!!!!!!!!!!!!!!!!!!\n"
  assert_foot = "\n!!!!!!!!!!!!!!!!!!!!!!!^^^^^^^^^^^^^^^^!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n"
  asserts = {
    for bucket, settings in local.buckets : bucket => merge({
      bucketname_too_long = length(settings.bucket_name) > 63 ? file(format("%sbucket %s's generated name is too long:\n%s\n%s > 63 chars!%s", local.assert_head, bucket, settings.bucket_name, length(settings.bucket_name)), local.assert_foot) : "ok"
      bucketname_regex    = length(regexall("^(([a-z0-9]|[a-z0-9][a-z0-9\\-]*[a-z0-9])\\.)*([a-z0-9]|[a-z0-9][a-z0-9\\-]*[a-z0-9])$", settings.bucket_name)) == 0 ? file(format("%sbucket %s's generated name %s does not match regex ^(([a-z0-9]|[a-z0-9][a-z0-9\\-]*[a-z0-9])\\.)*([a-z0-9]|[a-z0-9][a-z0-9\\-]*[a-z0-9])$%s", local.assert_head, bucket, settings.bucket_name, local.assert_foot)) : "ok"

      # This tests if caller provided keys are actually known to us, i.e. an easy mistake (but tough to spot) is to supply "settings" instead of "setting" for this module.
      keytest = {
        for setting in keys(settings) : setting => merge(
          {
            keytest = lookup(local.bucket_defaults, setting, "!TF_SETTINGTEST!") == "!TF_SETTINGTEST!" ? file(format("%sUnknown bucket variable assigned - bucket %s defines %q -- Please check for typos etc!%s", local.assert_head, bucket, setting, local.assert_foot)) : "ok"
        })
      }
    })
  }
}

#---------------------------------------------------------------------------------------------
# AWS Resources
#---------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "map" {
  for_each = local.buckets

  tags = merge(
    local.tags,
    # Bucket specific tags
    {
      "${local.company}:purpose" = each.key
      "${local.company}:owner"   = each.value.owner
    }
  )

  bucket = each.value.bucket_name

  force_destroy       = var.buckets_force_destroy # this should only be set to true if you want to destroy all resources inside the account.
  acceleration_status = each.value.acceleration_status
  region              = each.value.region
  acl                 = each.value.acl

  # One block allowed
  dynamic "website" {
    for_each = each.value.website[*]

    content {
      index_document           = website.value.index_document
      error_document           = website.value.error_document
      redirect_all_requests_to = website.value.redirect_all_requests_to
      routing_rules            = website.value.routing_rules
    }
  }

  # One block allowed
  dynamic "cors_rule" {
    for_each = each.value.cors_rule[*]

    content {
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      allowed_headers = cors_rule.value.allowed_headers
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }

  # One block allowed
  dynamic "versioning" {
    for_each = each.value.versioning[*]

    content {
      enabled    = versioning.value.enabled
      mfa_delete = versioning.value.mfa_delete
    }
  }

  # One block allowed
  dynamic "logging" {
    for_each = each.value.logging[*]

    content {
      target_bucket = logging.value.target_bucket
      target_prefix = logging.value.target_prefix
    }
  }

  # Multiple blocks allowed
  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules

    content {
      enabled                                = lifecycle_rule.value.enabled
      id                                     = lifecycle_rule.value.id
      prefix                                 = lifecycle_rule.value.prefix
      tags                                   = lifecycle_rule.value.tags
      abort_incomplete_multipart_upload_days = lifecycle_rule.value.abort_incomplete_multipart_upload_days

      # One block allowed
      dynamic "expiration" {
        for_each = lifecycle_rule.value.expiration[*]

        content {
          date                         = expiration.value.date
          days                         = expiration.value.days
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      # One block allowed
      dynamic "noncurrent_version_expiration" {
        for_each = lifecycle_rule.value.noncurrent_version_expiration[*]

        content {
          days = noncurrent_version_expiration.value.days
        }
      }

      # Multiple blocks allowed
      dynamic "noncurrent_version_transition" {
        for_each = lifecycle_rule.value.noncurrent_version_transition

        content {
          days          = noncurrent_version_transition.value.days
          storage_class = noncurrent_version_transition.value.storage_class
        }
      }

      # Multiple blocks allowed
      dynamic "transition" {
        for_each = lifecycle_rule.value.transition

        content {
          date          = transition.value.date
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
    }
  }

  # One block allowed
  dynamic "replication_configuration" {
    for_each = each.value.replication_configuration[*]

    content {
      role = replication_configuration.value.role

      # Multiple blocks allowed
      dynamic "rules" {
        for_each = replication_configuration.value.rules

        content {
          id       = lookup(rules.value, "id", null)
          priority = lookup(rules.value, "priority", null)
          status   = lookup(rules.value, "status", null)

          # One block allowed
          dynamic "destination" {
            for_each = rules.value.destination[*]

            content {
              bucket        = destination.value.bucket
              storage_class = destination.value.storage_class

              replica_kms_key_id = (rules.value.source_selection_criteria && rules.value.source_selection_criteria.sse_kms_encrypted_objects == "sse_kms_encrypted_objects" ? rules.value.destination.replica_kms_key_id : null)

              # The following two settings can only be used if both are set
              account_id = rules.value.destination.access_control_translation ? rules.value.destination.account_id : null
              dynamic "access_control_translation" {
                for_each = (lookup(destination.value, "account_id", null) || destination.value.access_control_translation == null) ? [] : [destination.value.access_control_translation]

                content {
                  owner = access_control_translation.value.owner
                }
              }
            }
          }

          dynamic "source_selection_criteria" {
            for_each = rules.value.source_selection_criteria[*]
            content {
              sse_kms_encrypted_objects {
                enabled = source_selection_criteria.value.sse_kms_encrypted_objects.enabled
              }
            }
          }

          dynamic "filter" {
            for_each = rules.value.filter[*]

            content {
              prefix = filter.value.prefix
              tags   = filter.value.tags
            }
          }
        }
      }
    }
  }

  # The key to use can be overwritten though
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = each.value.kms_encryption_key_id
      }
    }
  }

  # One block allowed
  dynamic "object_lock_configuration" {
    for_each = each.value.object_lock_configuration[*]

    content {
      object_lock_enabled = object_lock_configuration.value.object_lock_enabled

      # One block allowed
      dynamic "rule" {
        for_each = object_lock_configuration.value.rule[*]

        content {
          default_retention {
            mode  = rule.value.default_retention.mode
            days  = rule.value.default_retention.days
            years = rule.value.default_retention.years
          }
        }
      }
    }
  }
}

#data "google_iam_policy" "map" {
#  for_each = { for bucket, settings in local.buckets : bucket => settings if settings.roles != null }
#
#  dynamic "binding" {
#    for_each = each.value.roles
#
#    content {
#      role    = binding.key
#      members = binding.value
#    }
#  }
#}
#
#resource "google_storage_bucket_iam_policy" "map" {
#  for_each = data.google_iam_policy.map
#
#  bucket      = google_storage_bucket.map[each.key].name
#  policy_data = each.value.policy_data
#}
