module "route_switcher" {
  source    = "github.com/yandex-cloud-examples/yc-route-switcher"
  start_module          = false
  folder_id = yandex_resourcemanager_folder.folder[0].id
  route_table_folder_list = yandex_resourcemanager_folder.folder.*.id
  route_table_list      = flatten([[yandex_vpc_route_table.mgmt-rt.id], yandex_vpc_route_table.segment-rt.*.id])
  router_healthcheck_port = 80
  router_healthcheck_interval = 60
  back_to_primary = true
  routers = [
    {
      # fw-a
      healthchecked_ip = "${cidrhost(var.zone1_subnet_prefix_list[0], 10)}"
      healthchecked_subnet_id = yandex_vpc_subnet.zone1-subnet[0].id
      interfaces = flatten([
        [{
          # mgmt-int
          own_ip = yandex_compute_instance.fw-a.network_interface.0.ip_address
          backup_peer_ip = yandex_compute_instance.fw-b.network_interface.0.ip_address
        }],[
          # dmz and ohter interfaces
        for i in range(length(var.security_segment_names) - 2) : {
          own_ip           = yandex_compute_instance.fw-a.network_interface[i + 2].ip_address
          backup_peer_ip   = yandex_compute_instance.fw-b.network_interface[i + 2].ip_address 
        }]
      ])
    },
    {
      # fw-b
      healthchecked_ip = "${cidrhost(var.zone2_subnet_prefix_list[0], 10)}"
      healthchecked_subnet_id = yandex_vpc_subnet.zone2-subnet[0].id
      interfaces = flatten([
        [{
          # mgmt-int
          own_ip = yandex_compute_instance.fw-b.network_interface.0.ip_address
          backup_peer_ip = yandex_compute_instance.fw-a.network_interface.0.ip_address
        }],[
          # dmz and ohter interfaces
        for i in range(length(var.security_segment_names) - 2) : {
          own_ip           = yandex_compute_instance.fw-b.network_interface[i + 2].ip_address
          backup_peer_ip   = yandex_compute_instance.fw-a.network_interface[i + 2].ip_address 
        }]
      ])
    }
  ]
}
