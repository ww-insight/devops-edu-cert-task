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

////////////////////////////////////////////   container registry  ///////////////////////////////////////
resource "yandex_container_registry" "devops-cert" {
  name = "devops-cert"
}

////////////////////////////////////////////   devops-jenkins VM  ///////////////////////////////////////
resource "yandex_compute_instance" "devops-jenkins" {

  depends_on = [yandex_container_registry.devops-cert]

  name = "devops-jenkins"
  hostname = "devops-jenkins"

  allow_stopping_for_update = true

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: ${var.YA_USER}\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${file(local.YA_PUBKEY_FILE)}"
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
    cores  = 4
    memory = 4
  }
  scheduling_policy {
    preemptible = true
  }

  connection {
    type     = "ssh"
    user     = var.YA_USER
    private_key = "${file(local.YA_PRIVATEKEY_FILE)}"
    host     = self.network_interface.0.nat_ip_address
  }

  provisioner "file" {
    source = "secret.tfvar"
    destination = "secret.tfvar"
  }

  provisioner "file" {
    source = "Dockerfile"
    destination = "Dockerfile"
  }

  provisioner "file" {
    source = "terraform"
    destination = "terraform"
  }

  provisioner "file" {
    source = "terraformrc"
    destination = "terraformrc"
  }

  provisioner "remote-exec" {
    inline = [
       "sudo apt update"
      ,"sudo apt install docker.io -y"
      ,"sudo docker build -t my-jenkins ."
      ,"sudo docker run -u 0 -p 8080:8080 -p 50000:50000 -d -v /var/jenkins_home:/var/jenkins_home my-jenkins"
      ,"echo \"Waiting until Jenkins is started to print password...\""
      ,"sudo sh -c \"while [ ! -f /var/jenkins_home/secrets/initialAdminPassword ]; do sleep 3; done;\""
      ,"sudo echo '' >> secret.tfvar"
      ,"sudo echo 'YA_DOCKER_REG=\"${yandex_container_registry.devops-cert.id}\"' >> secret.tfvar"
      ,"sudo mv secret.tfvar /var/jenkins_home/secrets/secret.tfvar"
      ,"echo \"Jenkins pass:\""
      ,"sudo cat /var/jenkins_home/secrets/initialAdminPassword"
      ,"echo \"http://admin:$(cat /var/jenkins_home/secrets/initialAdminPassword)@localhost:8080/credentials/store/system/domain/_/createCredentials\" "
      ,"echo 'json={\": \"0\", \"credentials\": { \"scope\": \"GLOBAL\", \"id\": \"ya-cloud-cred\", \"username\": \"oauth\", \"password\": \"${var.YA_TOKEN}\", \"description\": \"ya-cloud-cred\", \"$class\": \"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\"} }'"
      ,"curl -X POST \"http://admin:$(cat /var/jenkins_home/secrets/initialAdminPassword)@localhost:8080/credentials/store/system/domain/_/createCredentials\" --data-urlencode 'json={\": \"0\", \"credentials\": { \"scope\": \"GLOBAL\", \"id\": \"ya-cloud-cred\", \"username\": \"oauth\", \"password\": \"${var.YA_TOKEN}\", \"description\": \"ya-cloud-cred\", \"$class\": \"com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl\"} }'"
    ]
  }
}

output "jenkin-url" {
  value = "http://${yandex_compute_instance.devops-jenkins.network_interface[0].nat_ip_address}:8080"
}

//////////////////////////////////////////////////////////////////////////////////////////////