terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.22.0"
    }
  }

  required_version = ">= 1.3.7"

  # Uncomment after creating the bucket
  # backend "s3" {
  #   bucket = "tfstate-bucket"
  #   key    = "terraform/state/bootstrap"
  #   region = "${var.region}"
  # }
}

############ IAM ##############

resource "aws_iam_policy" "webdriver_lambda_policy" {
  name        = "webdriver_lambda_policy"
  description = "webdriver_lambda_policy"

  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "S3Put",
          "Action": [
            "s3:PutObject",
            "s3:PutObjectAcl",
          ],
          "Effect": "Allow",
          "Resource": [
            "arn:aws:s3:::andyawson-ui-test/*",
          ]
        },
        {
            "Sid": "VPCattach",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:AttachNetworkInterface",
                "ec2:AssignPrivateIpAddresses",
                "ec2:UnassignPrivateIpAddresses",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces"
            ],
            "Resource": "*"
        }
      ]
    }
  )
}

# S3
resource "aws_s3_bucket" "andyawson-ui-test" {
  bucket = "andyawson-ui-test"
}

# Create lambda webdriver role for webdriver lambda
resource "aws_iam_role" "lambda_webdriver_role" {
  name = "lambda-webdriver-role"

  assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "Service": [
              "lambda.amazonaws.com"
            ]
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  )
}

# Create apigw role for api gateway
resource "aws_iam_role" "apigw_lambda_role" {
  name = "apigw-webdriver-role"

  assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "Service": [
              "lambda.amazonaws.com"
            ]
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  )
}

# Attach AWS managed policy AWSLambdaBasicExecutionRole to apigw role
resource "aws_iam_role_policy_attachment" "apigw_attachment" {
  role = "${aws_iam_role.apigw_lambda_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_policy" {
  role = "${aws_iam_role.lambda_webdriver_role.id}"
  policy_arn = "${aws_iam_policy.webdriver_lambda_policy.arn}"
}

# data for get aws account id
data "aws_caller_identity" "current" {}

# In according to https://github.com/hashicorp/terraform-provider-aws/issues/13625
# Create lambda permission for api gateway
resource "aws_lambda_permission" "apigw_permission" {
  # count = var.grant_lambda_for_apigw ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "guestbookwebdriver" // add a reference to your function name here
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API. the last one indicates where to send requests to.
  # see more detail https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway.html
  source_arn = "arn:aws:execute-api:ca-central-1:${data.aws_caller_identity.current.account_id}:${module.api_gateway.apigatewayv2_api_id}/*"
}

############# Lambda Resource ################

# Create lambda function for consumer
module "lambda_webdriver_role" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "guestbookwebdriver"
  description   = "Selenium WebDriver to test guestbook"
  handler       = "process.lambda_handler"
  runtime       = "python3.7"
  memory_size   = 512

  create = var.create_lambda2

  source_path = "aws/python/process.py"
  create_role = false
  lambda_role = "${aws_iam_role.lambda_webdriver_role.arn}"

  attach_policy_json = true

  timeout = 300
  layers = ["arn:aws:lambda:ca-central-1:698017650344:layer:selenium:1", "arn:aws:lambda:ca-central-1:698017650344:layer:chromdriver:1"]

  tags = {
    Name = "webdriver-lm-lambda"
  }
}

############ Create all API Gateway resources ##############

# Create log group in Cloudwatch for api gateway below
resource "aws_cloudwatch_log_group" "apigw_log_group" {
  name = "/aws/apigw/accesslog"
}

# Create api gateway
module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "prd-http"
  create        = var.create_apigw
  description   = "My awesome HTTP API Gateway"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  # Custom domain
  create_api_domain_name = false
  # domain_name                 = "terraform-aws-modules.modules.tf"
  # domain_name_certificate_arn = "arn:aws:acm:eu-west-1:052235179155:certificate/2b3a7ed9-05e1-4f9e-952b-27744ba06da6"

  # Access logs
  default_stage_access_log_destination_arn = "${aws_cloudwatch_log_group.apigw_log_group.arn}"
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  # Routes and integrations
  integrations = {
    # "ANY /failure" = {
    #   lambda_arn             = "${module.lambda_function_webdriver.lambda_function_arn}"
    #   payload_format_version = "2.0"
    #   timeout_milliseconds   = 12000
    # }

    "ANY /startwebdriver" = {
      lambda_arn             = "${module.lambda_webdriver_role.lambda_function_arn}"
      payload_format_version = "2.0"
      timeout_milliseconds   = 30000
    }
  }

  tags = {
    Name = "http-apigateway"
  }
}