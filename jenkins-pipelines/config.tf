terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}



variable "YA_TOKEN" {type = string}
variable "YA_CLOUD" {type = string}
variable "YA_FOLDER" {type = string}
variable "YA_SUBNET" {type = string}
variable "YA_USER" {type = string}
variable "YA_KEY_FOLDER" {type = string}

locals {
  YA_PUBKEY_FILE = "${var.YA_KEY_FOLDER}/id_rsa.pub"
  YA_PRIVATEKEY_FILE = "${var.YA_KEY_FOLDER}/id_rsa"
}

provider "yandex" {
  token     = var.YA_TOKEN
  cloud_id  = "cloud-ww-bel"
  folder_id = var.YA_FOLDER
  zone      = "ru-central1-b"
}

////////////////////////////////////////////   devops-builder VM  ///////////////////////////////////////
resource "yandex_compute_instance" "devops-builder" {

  name = "devops-builder"
  hostname = "devops-builder"

  allow_stopping_for_update = true

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: root\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${file(local.YA_PUBKEY_FILE)}"
  }
  boot_disk {
    initialize_params {
      image_id = "fd8qps171vp141hl7g9l" // Ubuntu 20.04
      size = "15"
    }
  }
  network_interface {
    subnet_id = var.YA_SUBNET
    nat = true
  }
  resources {
    cores  = 2
    memory = 2
  }
  scheduling_policy {
    preemptible = true
  }

  connection {
    type     = "ssh"
    user     = "root"
    private_key = "${file(local.YA_PRIVATEKEY_FILE)}"
    host     = self.network_interface.0.nat_ip_address
  }

  provisioner "remote-exec" {
    inline = [
       "sudo apt update"
      ,"sudo apt install python3"
    ]
  }
}

////////////////////////////////////////////   devops-prod VM  ///////////////////////////////////////
resource "yandex_compute_instance" "devops-prod" {

  name = "devops-prod"
  hostname = "devops-prod"

  allow_stopping_for_update = true

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: root\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${file(local.YA_PUBKEY_FILE)}"
  }
  boot_disk {
    initialize_params {
      image_id = "fd8qps171vp141hl7g9l" // Ubuntu 20.04
      size = "15"
    }
  }
  network_interface {
    subnet_id = var.YA_SUBNET
    nat = true
  }
  resources {
    cores  = 2
    memory = 2
  }
  scheduling_policy {
    preemptible = true
  }

  connection {
    type     = "ssh"
    user     = "root"
    private_key = "${file(local.YA_PRIVATEKEY_FILE)}"
    host     = self.network_interface.0.nat_ip_address
  }

  provisioner "remote-exec" {
    inline = [
       "sudo apt update"
      ,"sudo apt install python3"
      ,"pip install docker"
    ]
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////