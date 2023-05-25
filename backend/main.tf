resource "aws_dynamodb_table" "view-count" {
  name           = "view-count"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "count_id" # Partition key

  attribute {
    name = "count_id"
    type = "S" # Partition key data type
  }
}


# ------------------------------------
# ////////       Lambda       ////////
# ------------------------------------

# Execution Role
resource "aws_iam_role" "iam_lambda_role" {
  name = "iam_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Policy for Execution Role
resource "aws_iam_policy" "iam_policy_for_resume_project" {

  name        = "aws_iam_policy_for_terraform_resume_project_policy"
  path        = "/"
  description = "AWS IAM Policy for managing the resume project role"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:*",
          "Effect" : "Allow"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:UpdateItem",
            "dynamodb:GetItem",
            "dynamodb:PutItem"
          ],
          "Resource" : "arn:aws:dynamodb:*:*:table/view-count"
        },
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.iam_lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_resume_project.arn

}



# Function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function.zip"
}


resource "aws_lambda_function" "view-counter-function" {
  function_name = "view-counter-function"

  filename         = data.archive_file.lambda_zip.output_path # "update_view_count.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  role    = aws_iam_role.iam_lambda_role.arn
  handler = "view-counter-function.lambda_handler"
  runtime = "python3.9"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.view-count.id # Reference name of dynamodb table
    }
  }
}


# -----------------------------------------
# ////////       API Gateway       ////////
# -----------------------------------------

# REST API
resource "aws_api_gateway_rest_api" "api-to-lambda-view-count" {
  name        = "api-to-lambda-view-count"
  description = "Gateway -> Lambda -> DynamoDB"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# API Resource (path end for URL)
resource "aws_api_gateway_resource" "api-resource" {
  parent_id   = aws_api_gateway_rest_api.api-to-lambda-view-count.root_resource_id
  path_part   = "count"
  rest_api_id = aws_api_gateway_rest_api.api-to-lambda-view-count.id
}

# Request Method
resource "aws_api_gateway_method" "api-post-method" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.api-resource.id
  rest_api_id   = aws_api_gateway_rest_api.api-to-lambda-view-count.id
}
resource "aws_api_gateway_method" "api-get-method" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.api-resource.id
  rest_api_id   = aws_api_gateway_rest_api.api-to-lambda-view-count.id
}
# Integration (link to Lambda function)
resource "aws_api_gateway_integration" "api-lambda-integration" {
  rest_api_id             = aws_api_gateway_rest_api.api-to-lambda-view-count.id
  resource_id             = aws_api_gateway_resource.api-resource.id
  http_method             = aws_api_gateway_method.api-post-method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.view-counter-function.invoke_arn
}
resource "aws_api_gateway_integration" "api-lambda-get-integration" {
  rest_api_id             = aws_api_gateway_rest_api.api-to-lambda-view-count.id
  resource_id             = aws_api_gateway_resource.api-resource.id
  http_method             = aws_api_gateway_method.api-post-method.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.view-counter-function.invoke_arn
}
# Deployment (to stage for use)
resource "aws_api_gateway_deployment" "api-deployment" {
  rest_api_id = aws_api_gateway_rest_api.api-to-lambda-view-count.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.api-resource.id,
      aws_api_gateway_method.api-post-method.id,
      aws_api_gateway_integration.api-lambda-integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "api-stage" {
  deployment_id = aws_api_gateway_deployment.api-deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api-to-lambda-view-count.id
  stage_name    = "prod"
}

# Permission (from Lambda to API)
resource "aws_lambda_permission" "lambda-permission-to-api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "view-counter-function"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api-to-lambda-view-count.execution_arn}/${aws_api_gateway_stage.api-stage.stage_name}/${aws_api_gateway_method.api-post-method.http_method}/${aws_api_gateway_resource.api-resource.path_part}"
}


# -----------------------------------------
# ////////       Enable CORS      ////////
# -----------------------------------------

resource "aws_lambda_function_url" "url1" {
  function_name      = aws_lambda_function.view-counter-function.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["https://danielleniz.com"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}
