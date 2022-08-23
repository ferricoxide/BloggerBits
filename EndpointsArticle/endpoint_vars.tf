variable "vpc_endpoint_services" {
  default     = []
  description = "List of AWS Endpoint service names and types. Both Gateway and Interface Endpoints are supported. See https://docs.aws.amazon.com/general/latest/gr/rande.html for full list."
  type = list(
    object(
      {
        name = string
        type = string
      }
    )
  )
}

variable "create_sg_per_endpoint" {
  description = "Toggle to create a SecurityGroup for each VPC Endpoint. Defaults to using just one for all Interface Endpoints. Note that Gateway Endpoints don't support SecurityGroups."
  type        = bool
  default     = false
}

variable "endpoint_sg_list" {
  default     = []
  description = "List of security groups to apply to interface endpoints"
  type        = list(any)
}
