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

variable "activate_nat_gateway" {
    description = "to enable or disable net gateway"
    type = bool
    default = true
}