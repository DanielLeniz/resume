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