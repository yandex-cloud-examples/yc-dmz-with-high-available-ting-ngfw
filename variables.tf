variable "cloud_id" {
  description = "id for cloud in Yandex Cloud"
  default = null
}

variable "az_name_list" {
  type        = list(string)
  description = "List of availability zone names for resources"
  default     = ["ru-central1-a", "ru-central1-b"]
}

variable "security_segment_names" {
  type = list(string)
  description = "List of security segment names (The first one for management, the second for public internet, the third one for dmz, you can add more segments after the last one. Total number of segments should not be more than 7.)"
  default = ["demo-mgmt", "demo-public", "demo-dmz"]
}

variable "zone1_subnet_prefix_list" {
  type        = list(string)
  description = "List of prefixes in first availability zone for subnets corresponding to list of security segment names. One prefix per security segment."
  default     = []
}

variable "zone2_subnet_prefix_list" {
  type        = list(string)
  description = "List of prefixes in second availability zone for subnets corresponding to list of security segment names. One prefix per security segment."
  default     = []
}

variable "public_app_port" {
  type        = number
  description = "TCP port used for public application published in DMZ"
  default     = null 
}

variable "internal_app_port" {
  type        = number
  description = "Corresponding internal port for public application published in DMZ"
  default     = null 
}

variable "trusted_ip_for_access_jump-vm" {
  type = list(string)
  description = "Define list of trusted public IP addresses for connection to Jump VM"
  default = null
}

variable "wg_port" {
  type        = number
  description = "Port number for Wireguard Jump VM setting"
  default     = 51820 
}

variable "wg_client_dns" { 
  type        = string
  description = "DNS servers for Wireguard Jump VM setting"
  default = null
}

variable "vm_admin_username" {
  type        = string
  description = "admin username for VM"
  default = null
}

variable "fw_admin_username" {
  type        = string
  description = "admin username for FW"
  default = null
}


