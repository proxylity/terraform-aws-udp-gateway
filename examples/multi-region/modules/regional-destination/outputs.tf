output "bucket_info" {
  description = "Information about the regional S3 bucket"
  value = {
    name   = aws_s3_bucket.regional_bucket.bucket
    arn    = aws_s3_bucket.regional_bucket.arn
    region = aws_s3_bucket.regional_bucket.region
  }
}

output "destination_binding" {
  description = "Information about the destination ARN binding"
  value = {
    destination_name = var.destination_name
    destination_arn  = aws_s3_bucket.regional_bucket.arn
    region_key      = var.region
  }
}