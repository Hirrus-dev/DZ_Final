resource "aws_security_group" "ingress-all-test" {
    name = "allow-all-sg"
    
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 0
        to_port = 65535
        protocol = "tcp"
    }// Terraform removes the default rule
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "Build-server" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"
    key_name = file(var.pub_key})
    security_groups = ["${aws_security_group.ingress-all-test.id}"]

    tags {
        Name = "Build"
    }

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

resource "aws_instance" "Production-server" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "t3.micro"
    key_name = file(var.pub_key})
    security_groups = ["${aws_security_group.ingress-all-test.id}"]

    tags {
        Name = "Production"
    }
    depends_on = [aws_instance.Build-server]

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

