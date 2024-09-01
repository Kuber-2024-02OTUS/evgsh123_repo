resource "yandex_compute_instance" "cp" {
  count = 1
  name = "cp${count.index}"
  hostname = "cp${count.index}"

  platform_id = "standard-v1"

  resources {
    core_fraction = 20
    cores  = 2
    memory = 8
  }

  boot_disk {
    initialize_params {
      type = "network-ssd"
      image_id = "fd88m3uah9t47loeseir"
      size = 30
     }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.otus-subnet.id}"
    nat = true
     }

   metadata = {
     ssh-keys = "ubuntu:${trimspace(tls_private_key.ssh-key.public_key_openssh)}"
     user-data = file("${path.module}/userdata.yaml")
    }
  }
  resource "yandex_compute_instance" "worker" {
  count = 3
  name = "worker${count.index}"
  hostname = "worker${count.index}"

  platform_id = "standard-v1"

  resources {
    core_fraction = 20
    cores  = 2
    memory = 8
  }
  boot_disk {
    initialize_params {
      type = "network-ssd"
      image_id = "fd88m3uah9t47loeseir"
      size = 30
     }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.otus-subnet.id}"
    nat = true
     }

   metadata = {
     ssh-keys = "ubuntu:${trimspace(tls_private_key.ssh-key.public_key_openssh)}"
     user-data = file("${path.module}/userdata.yaml")
    }
}