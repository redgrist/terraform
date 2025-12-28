output "instance_id" {
  value = aws_instance.wg_client.id
}

output "instance_public_ip" {
  value = aws_instance.wg_client.public_ip
}

output "instance_public_dns" {
  value = aws_instance.wg_client.public_dns
}

output "wg_client_address" {
  value = var.wg_address
}

output "data_volume_id" {
  value = aws_ebs_volume.data.id
}

output "ssh_hint_over_wg" {
  value = "Po zestawieniu tunelu: ssh -i ${var.ssh_private_key_path != "" ? var.ssh_private_key_path : "<twoj_klucz>"} ec2-user@${replace(var.wg_address, "/32", "")}"
}

