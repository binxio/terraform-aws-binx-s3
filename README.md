# Module `terraform-aws-binx-s3

Creates S3 buckets in AWS
This module ensures the use of the right naming convention.
Example usage can be found in the `examples` directory.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| bucket\_defaults | Default settings to be used for your buckets so you don't need to provide them for each bucket separately. | <pre>object({<br><br>    force_destroy         = bool<br>    acceleration_status   = string<br>    region                = string<br>    acl                   = string<br>    kms_encryption_key_id = string<br><br>    website = object({<br>      index_document           = string<br>      error_document           = string<br>      redirect_all_requests_to = string<br>      routing_rules            = string<br>    })<br><br>    cors_rule = object({<br>      allowed_methods = list(string)<br>      allowed_origins = list(string)<br>      allowed_headers = list(string)<br>      expose_headers  = list(string)<br>      max_age_seconds = number<br>    })<br><br>    versioning = object({<br>      enabled    = bool<br>      mfa_delete = bool<br>    })<br><br>    logging = object({<br>      target_bucket = string<br>      target_prefix = string<br>    })<br><br>    lifecycle_rules = map(object({<br>      enabled                                = bool<br>      id                                     = string<br>      prefix                                 = string<br>      tags                                   = list(string)<br>      abort_incomplete_multipart_upload_days = number<br><br>      expiration = object({<br>        date                         = string<br>        days                         = number<br>        expired_object_delete_marker = bool<br>      })<br><br>      noncurrent_version_expiration = object({<br>        days = number<br>      })<br><br>      noncurrent_version_transition = map(object({<br>        days          = number<br>        storage_class = string<br>      }))<br><br>      transition = map(object({<br>        date          = string<br>        days          = number<br>        storage_class = string<br>      }))<br>    }))<br><br>    replication_configuration = object({<br>      role = string<br>      rules = map(object({<br>        id       = string<br>        priority = number<br>        status   = string<br><br>        destination = object({<br>          bucket             = string<br>          storage_class      = string<br>          replica_kms_key_id = string<br>          account_id         = string<br>          access_control_translation = object({<br>            owner = string<br>          })<br>        })<br><br>        source_selection_criteria = object({<br>          sse_kms_encrypted_objects = object({<br>            enabled = bool<br>          })<br>        })<br><br>        filter = object({<br>          prefix = string<br>          tags   = list(string)<br>        })<br>      }))<br>    })<br><br>    roles = map(list(string))<br>  })</pre> | <pre>{<br>  "acceleration_status": null,<br>  "acl": null,<br>  "cors_rule": null,<br>  "force_destroy": false,<br>  "kms_encryption_key_id": null,<br>  "lifecycle_rules": {},<br>  "logging": null,<br>  "region": "eu-west-1",<br>  "replication_configuration": null,<br>  "roles": {},<br>  "versioning": null,<br>  "website": null<br>}</pre> | no |
| buckets | Map of buckets to be created. The key will be used for the bucket name so it should describe the bucket purpose. The value can be a map with bucket setting objects. Refer to the bucket\_defaults variable to see the object definition. | `map(any)` | n/a | yes |
| buckets\_force\_destroy | When set to true, allows TFE to remove buckets that still contain objects | `bool` | `false` | no |
| environment | Environment for which the resources are created (e.g. dev, tst, acc or prd) | `string` | n/a | yes |
| project | Project name | `string` | n/a | yes |
| owner | Owner of the resource. This variable is used to set the 'owner' label. Will be used as default for each bucket, but can be overridden using the bucket settings | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| map | outputs for all aws\_s3\_buckets created |


## Managed Resources
* `aws_s3_bucket.map` from `aws`

## Required AWS IAM permissiosn
* s3.buckets.create

## Creating a new release
After adding your changed and committing the code to GIT, you will need to add a new tag.
```
git tag vx.x.x
git push --tag
```
If your changes might be breaking current implementations of this module, make sure to bump the major version up by 1.

If you want to see which tags are already there, you can use the following command:
```
git tag --list
```
