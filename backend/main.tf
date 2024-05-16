resource "aws_dynamodb_table" "view-count-table" {
  name           = "view-count-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id" # Partition key

  attribute {
    name = "id"
    type = "S" # Partition key data type
  }
}


# ------------------------------------
# ////////       Lambda       ////////
# ------------------------------------

# Execution Role
resource "aws_lambda_function" "myfunc" {
  filename         = data.archive_file.zip_the_python_code.output_path
  source_code_hash = data.archive_file.zip_the_python_code.output_base64sha256
  function_name    = "myfunc"
  role             = aws_iam_role.lambda_iam.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
}

resource "aws_iam_role" "lambda_iam" {
  name = "lambda_iam"

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
          "Resource" : "arn:aws:dynamodb:*:*:table/view-count-table"
        },
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role = aws_iam_role.lambda_iam.name
  policy_arn = aws_iam_policy.iam_policy_for_resume_project.arn
  
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function.zip"
}


# -----------------------------------------
# ////////       API Gateway       ////////
# -----------------------------------------

# REST API
resource "aws_api_gateway_rest_api" "resume-api" {
  name        = "resume-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

}
# API Resource (path end for URL)
resource "aws_api_gateway_resource" "api-resource" {
  parent_id   = aws_api_gateway_rest_api.resume-api.root_resource_id
  path_part   = "get_resume"
  rest_api_id = aws_api_gateway_rest_api.resume-api.id
}
# Request Method
resource "aws_api_gateway_method" "api-post-method" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.api-resource.id
  rest_api_id   = aws_api_gateway_rest_api.resume-api.id
}
resource "aws_api_gateway_method" "api-get-method" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.api-resource.id
  rest_api_id   = aws_api_gateway_rest_api.resume-api.id
}

# Integration (link to Lambda function)
resource "aws_api_gateway_integration" "api-lambda-post-integration" {
  rest_api_id             = aws_api_gateway_rest_api.resume-api.id
  resource_id             = aws_api_gateway_resource.api-resource.id
  http_method             = aws_api_gateway_method.api-post-method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.myfunc.invoke_arn
}
resource "aws_api_gateway_integration" "api-lambda-get-integration" {
  rest_api_id             = aws_api_gateway_rest_api.resume-api.id
  resource_id             = aws_api_gateway_resource.api-resource.id
  http_method             = aws_api_gateway_method.api-get-method.http_method
  integration_http_method = "GET"
  type                    = "AWS"
  uri                     = aws_lambda_function.myfunc.invoke_arn
}


# Deployment (to stage for use)
resource "aws_api_gateway_deployment" "api-deployment" {
  rest_api_id = aws_api_gateway_rest_api.resume-api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.api-resource.id,
      aws_api_gateway_method.api-post-method.id,
      aws_api_gateway_method.api-get-method.id,
      aws_api_gateway_integration.api-lambda-get-integration.id,
      aws_api_gateway_integration.api-lambda-post-integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "api-stage" {
  deployment_id = aws_api_gateway_deployment.api-deployment.id
  rest_api_id   = aws_api_gateway_rest_api.resume-api.id
  stage_name    = "dev"
}

# Permission (from Lambda to API)
resource "aws_lambda_permission" "lambda-permission-to-api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "myfunc"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.resume-api.execution_arn}/${aws_api_gateway_stage.api-stage.stage_name}/${aws_api_gateway_method.api-post-method.http_method}/${aws_api_gateway_resource.api-resource.path_part}"
}


# -----------------------------------------
# ////////       Enable CORS      ////////
# -----------------------------------------

resource "aws_lambda_function_url" "url1" {
  function_name      = aws_lambda_function.myfunc.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}
