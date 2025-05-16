// Create folders for security segments

resource "yandex_resourcemanager_folder" "folder" {
  count       = length(var.security_segment_names)
  cloud_id    = var.cloud_id
  name        = "${var.security_segment_names[count.index]}"
  description = "${var.security_segment_names[count.index]} security segment"
}
