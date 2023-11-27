############ IAM ##############

resource "aws_iam_policy" "cyberbullying_lambda_prd_policy" {
  name        = "cyberbullying_lambda_prd_policy"
  description = "cyberbullying_lambda_prd_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:CopyObject",
        "s3:HeadObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::dataset-3375-2",
        "arn:aws:s3:::dataset-3375-2/*"
      ]
    }
  ]
}
EOF
}

# Create p4o-lambda-consumer role for consumer lambda
resource "aws_iam_role" "lambda_cyberbully_prd_role" {
  name = "lambda-cyberbully-prd-role"

  assume_role_policy = <<EOF
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
EOF
}

# Create apigw role for api gateway
resource "aws_iam_role" "apigw_lambda_prd_role" {
  name = "apigw-cyberbully-prd-role"

  assume_role_policy = <<EOF
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
EOF
}

# Attach AWS managed policy AWSLambdaBasicExecutionRole to p4o-apigw role
resource "aws_iam_role_policy_attachment" "apigw_prd_attachment" {
  role = "${aws_iam_role.apigw_lambda_prd_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_prd_policy" {
  role = "${aws_iam_role.lambda_cyberbully_prd_role.id}"
  policy_arn = "${aws_iam_policy.cyberbullying_lambda_prd_policy.arn}"
}

# data for get aws account id
data "aws_caller_identity" "current" {}

# In according to https://github.com/hashicorp/terraform-provider-aws/issues/13625
# Create lambda permission for api gateway
resource "aws_lambda_permission" "apigw_prd_permission" {
  # count = var.grant_lambda_for_apigw ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "cyberbullyingpredict-prd" // add a reference to your function name here
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API. the last one indicates where to send requests to.
  # see more detail https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway.html
  source_arn = "arn:aws:execute-api:ca-central-1:${data.aws_caller_identity.current.account_id}:${module.api_gateway.apigatewayv2_api_id}/*"
}

############# Lambda Resource ################

# Create lambda function for consumer
module "lambda_function_cyberbullying_prd" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "cyberbullyingpredict-prd"
  description   = "ML for cyberbullying prediction"
  handler       = "process.lambda_handler"
  runtime       = "python3.8"
  memory_size   = "254"

  create = var.create_lambda2

  source_path = "aws/python/process.py"
  create_role = false
  lambda_role = "${aws_iam_role.lambda_cyberbully_prd_role.arn}"

  attach_policy_json = true

  timeout = 60
  layers = ["arn:aws:lambda:ca-central-1:698017650344:layer:python-3-8-scikit-learn-0-23-1:2", "arn:aws:lambda:ca-central-1:698017650344:layer:panda:1"]

  tags = {
    Name = "cyberbullying-lm-prd-lambda"
  }
}

############ Create all API Gateway resources ##############

# Create log group in Cloudwatch for api gateway below
resource "aws_cloudwatch_log_group" "apigw_log_prd_group" {
  name = "/aws/apigw/accesslog"
}

# Create api gateway
module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "prd-http-1"
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
  default_stage_access_log_destination_arn = "${aws_cloudwatch_log_group.apigw_log_prd_group.arn}"
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  # Routes and integrations
  integrations = {
    # "ANY /failure" = {
    #   lambda_arn             = "${module.lambda_function_cyberbullying.lambda_function_arn}"
    #   payload_format_version = "2.0"
    #   timeout_milliseconds   = 12000
    # }

    "ANY /cyberbullyingpredict" = {
      lambda_arn             = "${module.lambda_function_cyberbullying_prd.lambda_function_arn}"
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }
  }

  tags = {
    Name = "http-apigateway-prd"
  }
}