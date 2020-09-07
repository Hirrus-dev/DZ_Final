/*resource "digitalocean_spaces_bucket" "repo-2" {
    name   = "repo-2"
    region = "ams3"
    force_destroy = true

    provisioner "local-exec" {
        
        command = "sed \"/access_key/c access_key = ${file (var.s3_access_id)} \" .s3cfg.template > .s3cfg"
    }
    provisioner "local-exec" {
        command = "sed -i \"/secret_key/c secret_key = ${file (var.s3_secret_key)}\" .s3cfg"
    }
    provisioner "local-exec" {
        command = "sed -i \"/host_bucket/c host_bucket = ${var.s3-name}.ams3.digitaloceanspaces.com\" .s3cfg"
    }
}
*/
resource "digitalocean_droplet" "Build-server" {
    image = "ubuntu-18-04-x64"
    name = "Build"
    region = "fra1"
    size = "s-1vcpu-1gb"
     ssh_keys = [
      var.ssh_fingerprint
    ]
    connection {
        host = self.ipv4_address
        user = "root"
        type = "ssh"
        private_key = file(var.pvt_key)
        timeout = "2m"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo apt update",
            "sudo apt -y install python3",
            #"sudo apt -y install python3-pip",
            #"sudo pip3 install docker",
            "groupadd ansible",
            "useradd ansible -g ansible -s /bin/bash -d /home/ansible -p $(openssl passwd -6 ${file(var.ansible_user_password)})",
            "usermod -a -G sudo ansible",
            "mkdir -p /home/ansible/.ssh/",
            "chown -R ansible:ansible /home/ansible"
        ]
    }
    provisioner "local-exec" {
            command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.pvt_key} ~/.ssh/id_rsa.pub root@${self.ipv4_address}:/home/ansible/.ssh/authorized_keys"
    }
    provisioner "local-exec" {
            command = "echo \"${self.ipv4_address}\" > ~/ansible-roles/ip.build"
    }
    provisioner "local-exec" {
            command = "echo \"[Build]\nBuild-1 ansible_ssh_host=${self.ipv4_address} ansible_ssh_user=ansible\" > ~/ansible-roles/hosts"
    }
    provisioner "local-exec" {
            command = "ssh-keyscan -H ${self.ipv4_address} >> ~/.ssh/known_hosts"
    }
    provisioner "local-exec" {
            command = "sed -i 's/^ipregistry:.*/ipregistry: ${self.ipv4_address}/g' ../ansible-roles/Production/vars/main.yml"
    }
}

resource "digitalocean_droplet" "Production-server" {
    image = "ubuntu-18-04-x64"
    name = "Production"
    region = "fra1"
    size = "s-1vcpu-2gb"
     ssh_keys = [
      var.ssh_fingerprint
    ]
    depends_on = [digitalocean_droplet.Build-server]

    connection {
        host = self.ipv4_address
        user = "root"
        type = "ssh"
        private_key = file(var.pvt_key)
        timeout = "2m"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo apt update",
            "sudo apt -y install python3",
            #"sudo apt -y install python3-pip",
            #"sudo pip3 install docker",
            "groupadd ansible",
            "useradd ansible -g ansible -s /bin/bash -d /home/ansible -p $(openssl passwd -6 ${file(var.ansible_user_password)})",
            "usermod -a -G sudo ansible",
            "mkdir -p /home/ansible/.ssh/",
            "chown -R ansible:ansible /home/ansible"
        ]
    }
    provisioner "local-exec" {
            command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.pvt_key} ~/.ssh/id_rsa.pub root@${self.ipv4_address}:/home/ansible/.ssh/authorized_keys"
    }
    provisioner "local-exec" {
            command = "echo \"${self.ipv4_address}\" > ~/ansible-roles/ip.production"
    }
    provisioner "local-exec" {
            command = "echo \"[Production]\nProduction-1 ansible_ssh_host=${self.ipv4_address} ansible_ssh_user=ansible\" >> ~/ansible-roles/hosts"
    }
    provisioner "local-exec" {
            command = "ssh-keyscan -H ${self.ipv4_address} >> ~/.ssh/known_hosts"
    }
}

