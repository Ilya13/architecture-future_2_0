data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_vpc_network" "api_gateway_net" {
  name = "api-gateway-network"
}

resource "yandex_vpc_subnet" "api_gateway_subnet" {
  name           = "api-gateway-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.api_gateway_net.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

resource "yandex_compute_instance" "api_gateway_nodes" {
  count = 2

  name = "api-gateway-${count.index}"
  hostname = "api-gateway-${count.index}"

  zone = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = 10
      type     = "network-ssd"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.api_gateway_subnet.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

output "api_gateway_nodes_public_ips" {
  value = [
    for node in yandex_compute_instance.api_gateway_nodes :
    node.network_interface[0].nat_ip_address
  ]
  description = "Публичные IP всех узлов API Gateway"
}

output "api_gateway_nodes_internal_ips" {
  value = [
    for node in yandex_compute_instance.api_gateway_nodes :
    node.network_interface[0].ip_address
  ]
  description = "Внутренние IP всех узлов API Gateway"
}