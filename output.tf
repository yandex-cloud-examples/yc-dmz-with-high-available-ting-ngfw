output "path_for_private_ssh_key" {
  value = "./pt_key.pem"
}

output "fw-a_ip_address" {
  value = yandex_compute_instance.fw-a.network_interface.0.ip_address
}

output "fw-a_admin_password" {
  value = yandex_compute_instance.fw-a.id
}

output "fw-b_ip_address" {
  value = yandex_compute_instance.fw-b.network_interface.0.ip_address
}

output "fw-b_admin_password" {
  value = yandex_compute_instance.fw-b.id
}

output "jump-vm_public_ip_address_jump-vm" {
  value = yandex_vpc_address.public-ip-jump-vm.external_ipv4_address.0.address
}

output "jump-vm_path_for_WireGuard_client_config" {
  value = "./jump-vm-wg.conf"
}

output "fw-alb_public_ip_address" {
  value = yandex_vpc_address.public-ip-fw-alb.external_ipv4_address.0.address
}

output "dmz-web-server-nlb_ip_address" {
  value = "${cidrhost(var.zone1_subnet_prefix_list[2], 100)}"
}