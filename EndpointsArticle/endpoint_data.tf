locals {
  vpc_endpoint_services = length(var.vpc_endpoint_services) == 0 ? jsondecode(
    templatefile(
      "./endpoint_services.tpl.hcl",
      {
        endpoint_region = var.region
      }
    )
  ) : var.vpc_endpoint_services
}

data "aws_vpc_endpoint_service" "this" {
  for_each = {
    for service in local.vpc_endpoint_services :
    "${service.name}:${service.type}" => service
  }

  service_name = length(
    regexall(
      var.region,
      each.value.name
    )
  ) == 1 ? each.value.name : "com.amazonaws.${var.region}.${each.value.name}"
  service_type = title(each.value.type)
}
