//Create service accounts

// Service account for DMZ web-server Instange Group
resource "yandex_iam_service_account" "dmz-ig-sa" {
  folder_id = yandex_resourcemanager_folder.folder[2].id
  name = "dmz-ig-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "dmz-ig-sa_sa_roles" {
  folder_id = yandex_resourcemanager_folder.folder[2].id
  role   = "editor"
  member = "serviceAccount:${yandex_iam_service_account.dmz-ig-sa.id}"
}


//Create Security Groups

// Create security group in management segment
resource "yandex_vpc_security_group" "mgmt-sg" {
  name        = "mgmt-sg"
  description = "Security group for mgmt segment"
  folder_id   = yandex_resourcemanager_folder.folder[0].id
  network_id  = yandex_vpc_network.vpc[0].id

  ingress {
    protocol            = "TCP"
    description         = "NLB healthcheck"
    port                = 80
    predefined_target   = "loadbalancer_healthchecks"
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP from Jump VM"
    security_group_id   = yandex_vpc_security_group.mgmt-jump-vm-sg.id
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP"
    predefined_target   = "self_security_group"
  }  

  ingress {
    protocol            = "TCP"
    description         = "FW HTTPS port to connect from Jump VM"
    port                = 443
    security_group_id   = yandex_vpc_security_group.mgmt-jump-vm-sg.id
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH from Jump VM to other segment"
    port                = 22
    security_group_id   = yandex_vpc_security_group.mgmt-jump-vm-sg.id
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security group for Jump VM in management segment
resource "yandex_vpc_security_group" "mgmt-jump-vm-sg" {
  name        = "mgmt-jump-vm-sg"
  description = "Security group for Jump VM"
  folder_id   = yandex_resourcemanager_folder.folder[0].id
  network_id  = yandex_vpc_network.vpc[0].id

  ingress {
    protocol            = "UDP"
    description         = "WireGuard from trusted public IP addresses"
    port                = var.wg_port
    v4_cidr_blocks      = var.trusted_ip_for_access_jump-vm
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH from trusted public IP addresses"
    port                = 22
    v4_cidr_blocks      = var.trusted_ip_for_access_jump-vm
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security groups for ALB FW in public segment
resource "yandex_vpc_security_group" "public-fw-alb-sg" {
  name        = "public-fw-alb-sg"
  description = "Security group to allow NLB healthcheck for primary FW"
  folder_id   = yandex_resourcemanager_folder.folder[1].id
  network_id  = yandex_vpc_network.vpc[1].id

  ingress {
    protocol            = "TCP"
    description         = "ALB healthcheck"
    port                = 30080
    predefined_target   = "loadbalancer_healthchecks"
  }

  ingress {
    protocol            = "TCP"
    description         = "public app"
    port                = var.public_app_port
    v4_cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "FW-a and FW-b public interfaces IPs"
    v4_cidr_blocks = [
      "${yandex_compute_instance.fw-a.network_interface.1.ip_address}/32", 
      "${yandex_compute_instance.fw-b.network_interface.1.ip_address}/32"
    ]
  }
}

// Create security groups for primary FW in public segment
resource "yandex_vpc_security_group" "public-fw-sg" {
  name        = "public-fw-sg"
  description = "Security group to allow traffic from ALB for public app port"
  folder_id   = yandex_resourcemanager_folder.folder[1].id
  network_id  = yandex_vpc_network.vpc[1].id

  ingress {
    protocol            = "TCP"
    description         = "from ALB to public app internal port"
    port                = var.internal_app_port
    v4_cidr_blocks      = [var.zone1_subnet_prefix_list[1], var.zone2_subnet_prefix_list[1]]
  }

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


// Create security groups for web-servers in dmz segment
resource "yandex_vpc_security_group" "dmz-web-sg" {
  name        = "dmz-web-sg"
  description = "Security group for web-servers in dmz segment"
  folder_id   = yandex_resourcemanager_folder.folder[2].id
  network_id  = yandex_vpc_network.vpc[2].id

  ingress {
    protocol            = "ANY"
    description         = "NLB healthcheck for public app internal port"
    port                = var.internal_app_port
    predefined_target   = "loadbalancer_healthchecks"
  }

  ingress {
    protocol            = "TCP"
    description         = "public app internal port"
    port                = var.internal_app_port
    v4_cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH from management segment"
    port                = 22
    v4_cidr_blocks      = [
      var.zone1_subnet_prefix_list[0], 
      var.zone2_subnet_prefix_list[0]
    ]
  }

 egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

// Create security group for other segments, the one below is for testing purpose only, for production it should be changed accordingly
resource "yandex_vpc_security_group" "segment-sg" {
  count       = length(var.security_segment_names) - 2
  name        = "${var.security_segment_names[count.index + 2]}-sg"
  description = "Security group for ${var.security_segment_names[count.index + 2]} segment"
  folder_id   = yandex_resourcemanager_folder.folder[count.index + 2].id
  network_id  = yandex_vpc_network.vpc[count.index + 2].id

  ingress {
    protocol            = "TCP"
    description         = "HTTPS"
    port                = 443
    v4_cidr_blocks      = [
      yandex_vpc_subnet.zone1-subnet[count.index + 2].v4_cidr_blocks[0], 
      yandex_vpc_subnet.zone2-subnet[count.index + 2].v4_cidr_blocks[0]
    ]
  }

  ingress {
    protocol            = "TCP"
    description         = "SSH"
    port                = 22
    v4_cidr_blocks      = [
      yandex_vpc_subnet.zone1-subnet[count.index + 2].v4_cidr_blocks[0], 
      yandex_vpc_subnet.zone2-subnet[count.index + 2].v4_cidr_blocks[0]
    ]
  }

  ingress {
    protocol            = "ICMP"
    description         = "ICMP"
    v4_cidr_blocks      = [
      yandex_vpc_subnet.zone1-subnet[count.index + 2].v4_cidr_blocks[0], 
      yandex_vpc_subnet.zone2-subnet[count.index + 2].v4_cidr_blocks[0]
    ]
  }  

  egress {
    protocol       = "ANY"
    description    = "outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


