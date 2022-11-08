data "aws_caller_identity" "current" {}

# Create the S3 bucket
resource "aws_s3_bucket" "secure_bucket" {
    bucket        = "my-secure-bucket-39d1"
}

# Configure server side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enforce HTTPS transfers using TLS 1.2 or newer
resource "aws_s3_bucket_policy" "secure_bucket" {
    bucket = aws_s3_bucket.secure_bucket.id

    policy = jsonencode({
        Version = "2012-10-17"
        Id      = "BUCKET-POLICY"
        Statement = [
            {
                Sid       = "EnforceTls"
                Effect    = "Deny"
                Principal = "*"
                Action    = "s3:*"
                Resource = [
                    "${aws_s3_bucket.secure_bucket.arn}/*",
                    "${aws_s3_bucket.secure_bucket.arn}",
                ]
                Condition = {
                    Bool = {
                        "aws:SecureTransport" = "false"
                    }
                }
            },
            {
                Sid       = "EnforceProtoVer"
                Effect    = "Deny"
                Principal = "*"
                Action    = "s3:*"
                Resource = [
                    "${aws_s3_bucket.secure_bucket.arn}/*",
                    "${aws_s3_bucket.secure_bucket.arn}",
                ]
                Condition = {
                    NumericLessThan = {
                        "s3:TlsVersion": 1.2
                    }
                }
            }
        ]
    })
}

# Configure bucket logging
resource "aws_s3_bucket_logging" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = join("-", ["mybucket", "${data.aws_caller_identity.current.account_id}", "access", "logs"])
  target_prefix = "${aws_s3_bucket.secure_bucket.id}/"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
