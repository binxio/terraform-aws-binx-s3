output "map" {
  description = "outputs for all aws_s3_buckets created"
  value       = { for key, bucket in aws_s3_bucket.map : key => bucket }
}
