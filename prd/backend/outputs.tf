output "cyberbullying_apigw_url" {
    description = "The URI of the API"
    value = module.api_gateway.apigatewayv2_api_api_endpoint
}