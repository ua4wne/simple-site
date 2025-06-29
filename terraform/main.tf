# Создание сервисного аккаунта
resource "yandex_iam_service_account" "registry_push_pull" {
  name        = "registry-push-pull"
  description = "Service account for pushing and pulling to YCR"
}

# Назначение роли pusher (можно viewer, puller, editor, owner и т.д.)
resource "yandex_resourcemanager_folder_iam_member" "registry_push_role" {
  folder_id = var.folder_id
  role      = "container-registry.images.pusher"
  member    = "serviceAccount:${yandex_iam_service_account.registry_push_pull.id}"
}

# Назначение роли puller (можно viewer, puller, editor, owner и т.д.)
resource "yandex_resourcemanager_folder_iam_member" "registry_pull_role" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.registry_push_pull.id}"
}

# --- Container Registry ---
resource "yandex_container_registry" "main" {
  name      = "rai-diploma"
  folder_id = var.folder_id

  labels = {
    env = "production"
    app = "container-registry"
  }
}

# --- Формируем URL ---
locals {
  registry_url = "cr.yandex/${yandex_container_registry.main.id}"
}

# --- Формируем ключ доступа ---
resource "null_resource" "create_json_key" {
  depends_on = [yandex_iam_service_account.registry_push_pull]

  provisioner "local-exec" {
    command = <<EOT
      yc iam key create \
        --service-account-id ${yandex_iam_service_account.registry_push_pull.id} \
        --output key.json
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}

# --- Сборка и пуш через Docker CLI ---
resource "null_resource" "build_and_push_docker_image" {
  triggers = {
    registry_id  = yandex_container_registry.main.id
    image_tag    = "latest"
    docker_hash  = filesha1("../Dockerfile") # или другой файл
  }

  provisioner "local-exec" {
    command = <<EOT
      cat key.json | docker login \
        --username json_key \
        --password-stdin \
        cr.yandex
      echo "Сборка Docker-образа..."
      docker build -t ${local.registry_url}/app/site:latest -f ../Dockerfile ../
      echo "Пуш в Yandex Container Registry..."
      docker push ${local.registry_url}/app/site:latest
    EOT
    # rm key.json
  }
}
