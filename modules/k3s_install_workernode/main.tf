variable "connection" {
  type = map(any)
}

variable "master_ip" {
    type = string
}

variable "master_token" {
    type = string
}

variable "depends" {
  default = []
}

# warning! the outputs are not updated even if the trigger re-runs the command!
variable "trigger" {
  default = ""
}

locals {}

resource "null_resource" "k3s_install_workernode" {
  triggers = {
    trigger  = var.trigger
  }
  depends_on = [var.depends]

  connection {
    // Source <https://www.terraform.io/docs/provisioners/connection.html#argument-reference>
    type     = try(var.connection["type"], null)
    user     = try(var.connection["user"], null)
    password = try(var.connection["password"], null)
    host     = var.connection["host"] //Required
    port     = try(var.connection["port"], null)
    timeout  = try(var.connection["timeout"], null)

    private_key    = try(var.connection["private_key"], null)
    certificate    = try(var.connection["certificate"], null)
    agent          = try(var.connection["agent"], null)
    agent_identity = try(var.connection["agent_identity"], null)
    host_key       = try(var.connection["host_key"], null)

    https    = try(var.connection["https"], null)
    insecure = try(var.connection["insecure"], null)
    use_ntlm = try(var.connection["use_ntlm"], null)
    cacert   = try(var.connection["cacert"], null)

    bastion_host        = try(var.connection["bastion_host"], null)
    bastion_host_key    = try(var.connection["bastion_host_key"], null)
    bastion_port        = try(var.connection["bastion_port"], null)
    bastion_user        = try(var.connection["bastion_user"], null)
    bastion_password    = try(var.connection["bastion_password"], null)
    bastion_private_key = try(var.connection["bastion_private_key"], null)
    bastion_certificate = try(var.connection["bastion_certificate"], null)
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | K3S_URL=https://192.168.0.28:6443 K3S_TOKEN=K104f9eecea5177dcd1b5d67728662c84d04c635aa2cc48c69ed5b2662526fc01e7::server:fbca5e7274f6cb472aa6d4a85271ddda sh -",
      "sleep 5",      
    ]
  }
}
