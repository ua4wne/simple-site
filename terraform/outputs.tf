output "registry_url" {
  value = local.registry_url
}

# output "registry_sa_json_key" {
#   value     = yandex_iam_service_account_key.registry_key.private_key
#   # sensitive = true
# }