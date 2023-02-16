# resource "local_file" "hosts_file" {
#     content  = <<EOF
#     [${var.service_name}]
#     ${var.private_ip}
#     EOF
#     filename = "hosts"
#     file_permission = "0644"
# }