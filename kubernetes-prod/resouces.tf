resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = "${tls_private_key.ssh-key.private_key_openssh}"
  filename = "${path.module}/out/ssh.key"
}


resource "yandex_vpc_network" "otus-net" {}

resource "yandex_vpc_subnet" "otus-subnet" {
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.otus-net.id}"
  v4_cidr_blocks = ["10.5.0.0/24"]
}