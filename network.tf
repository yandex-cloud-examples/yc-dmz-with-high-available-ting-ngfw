// Create VPC networks for segments
resource "yandex_vpc_network" "vpc" {
  count = length(var.security_segment_names)
  name  = "${var.security_segment_names[count.index]}-vpc"
  folder_id = yandex_resourcemanager_folder.folder[count.index].id
}

// Create subnets for segments
resource "yandex_vpc_subnet" "zone1-subnet" {
  count          = length(var.security_segment_names)
  name           = "${var.security_segment_names[count.index]}-subnet-${substr(var.az_name_list[0], -1, -1)}"
  folder_id      = yandex_resourcemanager_folder.folder[count.index].id
  zone           = var.az_name_list[0]
  network_id     = yandex_vpc_network.vpc[count.index].id
  v4_cidr_blocks = [var.zone1_subnet_prefix_list[count.index]]
  route_table_id = count.index == 0 ? yandex_vpc_route_table.mgmt-rt.id : ( count.index == 1 ? null : yandex_vpc_route_table.segment-rt[count.index - 2].id )
}

resource "yandex_vpc_subnet" "zone2-subnet" {
  count          = length(var.security_segment_names)
  name           = "${var.security_segment_names[count.index]}-subnet-${substr(var.az_name_list[1], -1, -1)}"
  folder_id      = yandex_resourcemanager_folder.folder[count.index].id
  zone           = var.az_name_list[1]
  network_id     = yandex_vpc_network.vpc[count.index].id
  v4_cidr_blocks = [var.zone2_subnet_prefix_list[count.index]]
  route_table_id = count.index == 0 ? yandex_vpc_route_table.mgmt-rt.id : ( count.index == 1 ? null : yandex_vpc_route_table.segment-rt[count.index - 2].id )
}

// Create static routes for mgmt segment
resource "yandex_vpc_route_table" "mgmt-rt" {
  folder_id = yandex_resourcemanager_folder.folder[0].id
  network_id = yandex_vpc_network.vpc[0].id
  name = "mgmt-rt"

  dynamic "static_route" {
    for_each = slice(var.zone1_subnet_prefix_list, 1, length(var.security_segment_names))
    content {
      destination_prefix  = static_route.value
      next_hop_address    = "${cidrhost(var.zone1_subnet_prefix_list[0], 10)}"
    }
  }

  dynamic "static_route" {
    for_each = slice(var.zone2_subnet_prefix_list, 1, length(var.security_segment_names))
    content {
      destination_prefix  = static_route.value
      next_hop_address    = "${cidrhost(var.zone1_subnet_prefix_list[0], 10)}"
    }
  }

}

// Create static routes for other segments except mgmt and public
resource "yandex_vpc_route_table" "segment-rt" {
  count       = length(var.security_segment_names) - 2
  folder_id   = yandex_resourcemanager_folder.folder[count.index + 2].id
  network_id  = yandex_vpc_network.vpc[count.index + 2].id
  name        = "${var.security_segment_names[count.index + 2]}-rt"

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "${cidrhost(var.zone1_subnet_prefix_list[count.index + 2], 10)}"
  }
}


// Static public IP for fw ALB
resource "yandex_vpc_address" "public-ip-fw-alb" {
  name = "public-ip-fw-alb"
  folder_id = yandex_resourcemanager_folder.folder[1].id
  external_ipv4_address {
    zone_id = var.az_name_list[0]
  }
}

// Static public IP for FW-A
resource "yandex_vpc_address" "public-ip-fw-a" {
  name = "public-ip-fw-a"
  folder_id = yandex_resourcemanager_folder.folder[0].id
  external_ipv4_address {
    zone_id = var.az_name_list[0]
  }
}

// Static public IP for FW-B
resource "yandex_vpc_address" "public-ip-fw-b" {
  name = "public-ip-fw-b"
  folder_id = yandex_resourcemanager_folder.folder[0].id
  external_ipv4_address {
    zone_id = var.az_name_list[1]
  }
}

// Static public IP for Jump VM
resource "yandex_vpc_address" "public-ip-jump-vm" {
  name = "public-ip-jump-vm"
  folder_id = yandex_resourcemanager_folder.folder[0].id
  external_ipv4_address {
    zone_id = var.az_name_list[0]
  }
}


