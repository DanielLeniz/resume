 #S3 Bucket for TF State File
 resource "aws_s3_bucket" "terraform_state" {
    bucket = var.bucket_name
    force_destroy = true
 }

 resource "aws_s3_bucket_versioning" "terraform_bucket_versioning" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }
 }

 resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_crypto_config" {
    bucket = aws_s3_bucket.terraform_state.bucket
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
 }

 #Dynamo DB Table for Locking TF Config
 resource "aws_dynamodb_table" "terraform_locks" {
    name = "terraform-state-locking"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    attribute {
      name = "LockID"
      type = "S"
    }
 }

 #Dynamo DB Count
 resource "aws_dynamodb_table" "crc" {
    name = "view_count_terraform"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "id"

    attribute {
      name = "id"
      type = "S"
    }
}

resource "aws_dynamodb_table_item" "crc" {
    table_name = aws_dynamodb_table.crc.name
    hash_key = aws_dynamodb_table.crc.hash_key
    item = <<ITEM
    {
        "id" : { "S": "0" },
        "view_count": { "N": "1" }
    }
    ITEM
}