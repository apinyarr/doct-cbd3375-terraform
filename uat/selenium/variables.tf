variable "region" {
    description = "aws region"
    type = string
    default = "ca-central-1"
}

variable "create_lambda2" {
    description = "option to provision lambda2"
    type = bool
    default = true
}

variable "create_apigw" {
    description = "option to provision apigw"
    type = bool
    default = true
}

variable "lambda_function_arn" {
    description = "lambda2 arn"
    type = string
    default = ""
}