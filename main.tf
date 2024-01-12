terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token = var.my_token
  cloud_id = var.cloud_id
  folder_id = var.folder_id
#  zone = "ru-central1-a"
}


#Первая
resource "yandex_compute_instance" "vm-1" { 

  name                      = "nginx1"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-a"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd89iq8mqvli97d9poej"
      size = 10
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
  }

scheduling_policy {
    preemptible = true
  }

metadata = {
  user-data = "${file("./user.yml")}"
  }
}

#Вторая
resource "yandex_compute_instance" "vm-2" {

  name                      = "nginx2"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-b"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd89iq8mqvli97d9poej"
      size = 10
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-2.id}"
    nat       = true
  }

scheduling_policy {
    preemptible = true
  }

metadata = {
  user-data = "${file("./user.yml")}"
  }
}

#Target Group
resource "yandex_alb_target_group" "my-gr" {
  name      = "my-target-group"

  target {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    ip_address   = yandex_compute_instance.vm-1.network_interface.0.ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.subnet-2.id
    ip_address   = yandex_compute_instance.vm-2.network_interface.0.ip_address
  }
}






#Третья
resource "yandex_compute_instance" "vm-3" {

  name                      = "zabbix"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd89iq8mqvli97d9poej"
      size = 10
   }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
  }

scheduling_policy {
    preemptible = true
  }

metadata = {
  user-data = "${file("./user.yml")}"
  }
}

#Четвертая
resource "yandex_compute_instance" "vm-4" {

  name                      = "elasticsearch"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd89iq8mqvli97d9poej"
      size = 10
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
  }

scheduling_policy {
    preemptible = true
  }

metadata = {
  user-data = "${file("./user.yml")}"
  }
}

#Пятая 
resource "yandex_compute_instance" "vm-5" {

  name                      = "kibana"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd89iq8mqvli97d9poej"
      size = 10
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
  }

scheduling_policy {
    preemptible = true
  }

metadata = {
  user-data = "${file("./user.yml")}"
  }
}


#Outputs

output "external_ip_vm_1" {
value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}
output "external_ip_vm_2" {
value = yandex_compute_instance.vm-2.network_interface.0.nat_ip_address
}
output "external_ip_vm_3" {
value = yandex_compute_instance.vm-3.network_interface.0.nat_ip_address
}
output "external_ip_vm_4" {
value = yandex_compute_instance.vm-4.network_interface.0.nat_ip_address
}
output "external_ip_vm_5" {
value = yandex_compute_instance.vm-5.network_interface.0.nat_ip_address
}



#Сеть
resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

#Подсеть1
resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = "${yandex_vpc_network.network-1.id}"
}

#Подсеть2
resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet2"
  zone           = "ru-central1-b"
  v4_cidr_blocks = ["192.168.12.0/24"]
  network_id     = "${yandex_vpc_network.network-1.id}"
}


#L-7_load_balancer
resource "yandex_alb_load_balancer" "my-balancer" {
  name        = "load-balancer"

  network_id  = yandex_vpc_network.network-1.id
#  security_group_ids = ["<список_идентификаторов_групп_безопасности>"]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet-1.id 
    }
  }

  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
  }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.my-router.id
      }
    }
  }

  log_options {
#    log_group_id = "<идентификатор_лог-группы>"
    discard_rule {
#      http_codes          = ["<HTTP-код>"]
      http_code_intervals = ["HTTP_ALL"]
#      grpc_codes          = ["<gRPC-код>"]
      discard_percent     = 75
    }
  }
}

#HTTP_Router

resource "yandex_alb_http_router" "my-router" {
  name      = "my-http-router"
  labels = {
    tf-label    = "tf-label-value"
    empty-label = ""
  }
}

resource "yandex_alb_virtual_host" "my-router" {
  name      = "my-router"
  http_router_id = yandex_alb_http_router.my-router.id
  route {
    name = "my-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.my-bg.id
        timeout = "3s"
      }
    }
  }
}

#Backend GROUP

resource "yandex_alb_backend_group" "my-bg" {
  name      = "my-backend-group"

  http_backend {
    name = "test-http-backend"
    weight = 1
    port = 80
    target_group_ids = ["${yandex_alb_target_group.my-gr.id}"]
    tls {
      sni = "backend-domain.internal"
    }
    load_balancing_config {
      panic_threshold = 50
    }    
    healthcheck {
      healthcheck_port        = 80
      timeout = "1s"
      interval = "1s"
      http_healthcheck {
        path  = "/"
      }
    }
#    http2 = "true"
  }
}





#Snapshot
#1
#resource "yandex_compute_snapshot" "snapshot-1" {
#  name           = "disk-snapshot1"
#  source_disk_id = "${yandex_compute_instance.vm-1.boot_disk[0].disk_id}"
#}
#
#
#resource "yandex_compute_snapshot_schedule" "snapshot-1" {
#  schedule_policy {
#	expression = "0 0 * * *"
#  }
#
#  retention_period = "12h"
#
#  snapshot_spec {
#	  description = "retention-snapshot-1"
#  }
#
#  disk_ids = ["${yandex_compute_instance.vm-1.boot_disk[0].disk_id}"]
#}
#
#2
#resource "yandex_compute_snapshot" "snapshot-2" {
#  name           = "disk-snapshot2"
#  source_disk_id = "${yandex_compute_instance.vm-2.boot_disk[0].disk_id}"
#}
#
#
#resource "yandex_compute_snapshot_schedule" "snapshot-2" {
#  schedule_policy {
#        expression = "0 0 * * *"
#  }
#
#  retention_period = "12h"
#
#  snapshot_spec {
#          description = "retention-snapshot-2"
#  }
#
#  disk_ids = ["${yandex_compute_instance.vm-2.boot_disk[0].disk_id}"]
#}











