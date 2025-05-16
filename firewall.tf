data "yandex_compute_image" "ting_image" {
  family = "smartsoft-smart-soft-ting-ngfw-utm-fstek"
}

locals {
  // fw-a interfaces
  fw_a_interfaces = flatten([[{
    // mgmt fw-a interface
    index               = 0
    subnet_id           = yandex_vpc_subnet.zone1-subnet[0].id
    ip_address          = "${cidrhost(var.zone1_subnet_prefix_list[0], 10)}" 
    nat                 = false
    nat_ip_address      = null
    security_group_ids  = [yandex_vpc_security_group.mgmt-sg.id] 
  }],[{
    // public fw-a interface
    index               = 1
    subnet_id           = yandex_vpc_subnet.zone1-subnet[1].id
    ip_address          = "${cidrhost(var.zone1_subnet_prefix_list[1], 10)}" 
    nat                 = true
    nat_ip_address      = yandex_vpc_address.public-ip-fw-a.external_ipv4_address.0.address
    security_group_ids  = [yandex_vpc_security_group.public-fw-sg.id]
  }],
  [
    // dmz and ohter fw-a interfaces
    for i in range(length(var.security_segment_names) - 2) : {
      index               = i + 2
      subnet_id           = yandex_vpc_subnet.zone1-subnet[i + 2].id
      ip_address          = "${cidrhost(var.zone1_subnet_prefix_list[i + 2], 10)}" 
      nat                 = false
      nat_ip_address      = null
      security_group_ids  = [yandex_vpc_security_group.segment-sg[i].id]
    }
  ]])

  // fw-b interfaces
  fw_b_interfaces = flatten([[{
    // mgmt fw-b interface
    index               = 0
    subnet_id           = yandex_vpc_subnet.zone2-subnet[0].id
    ip_address          = "${cidrhost(var.zone2_subnet_prefix_list[0], 10)}" 
    nat                 = false
    nat_ip_address      = null
    security_group_ids  = [yandex_vpc_security_group.mgmt-sg.id] 
  }],[{
    // public fw-b interface
    index               = 1
    subnet_id           = yandex_vpc_subnet.zone2-subnet[1].id
    ip_address          = "${cidrhost(var.zone2_subnet_prefix_list[1], 10)}" 
    nat                 = true
    nat_ip_address      = yandex_vpc_address.public-ip-fw-b.external_ipv4_address.0.address
    security_group_ids  = [yandex_vpc_security_group.public-fw-sg.id]
  }],
  [
    // dmz and ohter fw-b interfaces
    for i in range(length(var.security_segment_names) - 2) : {
      index               = i + 2
      subnet_id           = yandex_vpc_subnet.zone2-subnet[i + 2].id
      ip_address          = "${cidrhost(var.zone2_subnet_prefix_list[i + 2], 10)}" 
      nat                 = false
      nat_ip_address      = null
      security_group_ids  = [yandex_vpc_security_group.segment-sg[i].id]
    }
  ]])
}

// Create FW-A
resource "yandex_compute_instance" "fw-a" {
  folder_id = yandex_resourcemanager_folder.folder[0].id
  name        = "fw-a"
  zone        = var.az_name_list[0]
  hostname    = "fw-a"
  platform_id = "standard-v3"
  allow_stopping_for_update = true
  
  resources {
    cores  = 4
    memory = 8
  }
  
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ting_image.id
      type     = "network-ssd"
      size     = 100
    }
  }
  
  dynamic "network_interface" {
    for_each = local.fw_a_interfaces
    content {
      index               = network_interface.value.index
      subnet_id           = network_interface.value.subnet_id
      ip_address          = network_interface.value.ip_address
      nat                 = network_interface.value.nat
      nat_ip_address      = network_interface.value.nat_ip_address
      security_group_ids  = network_interface.value.security_group_ids
    }
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys = "${var.fw_admin_username}:${chomp(tls_private_key.ssh.public_key_openssh)}"
  }
}

// Create FW-B
resource "yandex_compute_instance" "fw-b" {
  folder_id = yandex_resourcemanager_folder.folder[0].id
  name        = "fw-b"
  zone        = var.az_name_list[1]
  hostname    = "fw-b"
  platform_id = "standard-v3"
  allow_stopping_for_update = true
  
  resources {
    cores  = 4
    memory = 8
  }
  
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ting_image.id
      type     = "network-ssd"
      size     = 100
    }
  }
  
  dynamic "network_interface" {
    for_each = local.fw_b_interfaces
    content {
      index               = network_interface.value.index
      subnet_id           = network_interface.value.subnet_id
      ip_address          = network_interface.value.ip_address
      nat                 = network_interface.value.nat
      nat_ip_address      = network_interface.value.nat_ip_address
      security_group_ids  = network_interface.value.security_group_ids
    }
  }

  metadata = {
    serial-port-enable = 1
    ssh-keys = "${var.fw_admin_username}:${chomp(tls_private_key.ssh.public_key_openssh)}"
  }
}