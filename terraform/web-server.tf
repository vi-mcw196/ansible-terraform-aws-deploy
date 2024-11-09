# Utworzenie instanci EC2
resource "aws_instance" "web_server" {
  ami           = "ami-0866a3c8686eaeeba" # Ubuntu 24.04 LTS us-west-1
  instance_type = "t2.micro"

  security_groups = [aws_security_group.web_server.name]

  key_name = "vockey"

  tags = {
    Name = var.web_server_name
  }
}

# Konfiguracja pliku inventory dla Ansible
resource "local_file" "ip" {
  content  = <<-EOT
  [webservers]
  ${aws_instance.web_server.public_ip}
  EOT
  filename = "ansible/inventory.ini"
}

# Tymczasowe połączenia, do sprawdzenia czy maszyna jest dostępna
resource "terraform_data" "ssh_connection" {
  provisioner "remote-exec" {
    inline = [
      "echo \"$HOSTNAME connected...\""
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand(".ssh/labsuser.pem"))
    host        = aws_instance.web_server.public_ip
  }
}

# Uruchomienie procesu konfiguracji serwera z użyciem Ansible
resource "terraform_data" "ansible_provisioner" {
  provisioner "local-exec" {
    working_dir = "ansible/"
    command     = "ansible-playbook web_server.yml"
  }
  depends_on = [
    terraform_data.ssh_connection
  ]
}

# Wyświetlenie konfiguracji hosta
output "instance_ip_address" {
  value = aws_instance.web_server.public_ip
}

output "instance_dns_address" {
  value = aws_instance.web_server.public_dns
}
