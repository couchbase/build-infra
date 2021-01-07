resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${local.name}-robot"
  public_key = tls_private_key.main.public_key_openssh
}

resource "null_resource" "save_key" {
  depends_on = [tls_private_key.main]
  triggers = {
    missing = fileexists(local.ssh_key_path)
  }
  provisioner "local-exec" {
    command = "echo '${tls_private_key.main.private_key_pem}' > ${local.ssh_key_path} && chmod 600 ${local.ssh_key_path}"
  }
}
