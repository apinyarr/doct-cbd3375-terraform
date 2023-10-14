variable "region" {
    description = "aws region"
    type = string
    default = "ca-central-1"
}

variable "create_data_ml_server" {
    description = "to enable or disable data and ML server"
    type = bool
    default = true
}

# variable "ops_pre_peering" {
#     description = "vpc peering between ops and pre"
#     type = string
#     default = "pcx-06d415c4776e50a9c"
# }