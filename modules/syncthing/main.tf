variable "connection" {
  type = map(any)
}

variable "user" {
  default = "sfernandez"
}

variable "listenIp" {
    default = "127.0.0.1"
}

variable "depends" {
  default = []
}

# warning! the outputs are not updated even if the trigger re-runs the command!
variable "trigger" {
  default = ""
}

locals {}

resource "null_resource" "syncthing_install" {
  triggers = {
      user = var.user
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
      # Add the release PGP keys:
      "curl -s https://syncthing.net/release-key.txt | sudo apt-key add -",

      # Add the "stable" channel to your APT sources:
      "echo \"deb https://apt.syncthing.net/ syncthing stable\" | sudo tee /etc/apt/sources.list.d/syncthing.list",

      # Update and install syncthing:
      "sudo apt-get update",
      "sudo apt-get install syncthing -y",

      "sudo systemctl enable syncthing@${var.user}.service",
      "sudo systemctl start syncthing@${var.user}.service",
      #Give syncthing a moment
      "sleep 10",
      "systemctl status syncthing@${var.user} --no-pager -l",
    ]
  }
}

resource "null_resource" "syncthing_config" {
  triggers = {
    trigger  = var.trigger
    user     = var.user
    listenIp = var.listenIp
  }
  depends_on = [var.depends, null_resource.syncthing_install]

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
      "sudo systemctl stop syncthing@${var.user}.service",
      #Give syncthing a moment
      "sleep 5",
      "sed -i \"s/<address>.*:8384<\\/address>/<address>${var.listenIp}:8384<\\/address>/g\" /home/${var.user}/.config/syncthing/config.xml",
      "sed -i \"s/<urAccepted>.*<\\/urAccepted>/<urAccepted>-1<\\/urAccepted>/g\" /home/${var.user}/.config/syncthing/config.xml",
      "sed -i \"s/<urSeen>.*<\\/urSeen>/<urSeen>3<\\/urSeen>/g\" /home/${var.user}/.config/syncthing/config.xml",
      "sudo systemctl start syncthing@${var.user}.service",
      "systemctl status syncthing@${var.user} --no-pager -l",
      #Give syncthing a moment
      "sleep 10",
    ]
  }
}