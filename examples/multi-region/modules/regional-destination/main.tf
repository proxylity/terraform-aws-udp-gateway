# Regional S3 bucket for UDP packet storage
resource "aws_s3_bucket" "regional_bucket" {
  bucket = "proxylity-udp-data-${var.region}-${var.suffix}"

  tags = merge(var.tags, {
    Region = var.region
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "regional_bucket_versioning" {
  bucket = aws_s3_bucket.regional_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "regional_bucket_encryption" {
  bucket = aws_s3_bucket.regional_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Regional IAM policy for this specific bucket
resource "aws_iam_role_policy" "regional_s3_policy" {
  name = "proxylity-s3-policy-${var.region}"
  role = basename(var.global_role_arn)  # Extract role name from ARN

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.regional_bucket.arn,
          "${aws_s3_bucket.regional_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Bind this regional S3 bucket to the listener destination
module "destination_arn_binding" {
  source = "../../../../modules/proxylity_destination_arn"

  destination_name   = var.destination_name
  destination_arn    = aws_s3_bucket.regional_bucket.arn
  ingress_region_key = var.region

  tags = merge(var.tags, {
    Region = var.region
    Purpose = "regional-storage"
  })
}