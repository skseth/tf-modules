
resource "uidai_mysql_replica" "main" {
  name = var.name
  db = {
    "hdc" = {
      host     = var.hdc_db.host
      port     = var.hdc_db.port
      username = var.hdc_db.username
      password = var.hdc_db.password 
      default_source_host = var.hdc_db.default_source_host
      default_source_port = var.hdc_db.default_source_port
      replica_user     = var.hdc_db.replica_user
      replica_password = var.hdc_db.replica_password
      repl_host        = var.hdc_db.repl_host
    },

    "mndc" = {
      host     = var.mndc_db.host
      port     = var.mndc_db.port
      username = var.mndc_db.username
      password = var.mndc_db.password 
      default_source_host = var.mndc_db.default_source_host
      default_source_port = var.mndc_db.default_source_port
      replica_user     = var.mndc_db.replica_user
      replica_password = var.mndc_db.replica_password
      repl_host        = var.mndc_db.repl_host
    },
  }

  # target_primary_location = uidai_dcswitch.enu_backend.primary_location
  target_primary_location = var.target_primary_location
  current_location = var.current_location
  is_disconnected = var.locations_disconnected

  do_switch = var.do_switch

}

output "mndc_status" {
  value = resource.uidai_mysql_replica.main.db.mndc.status
}


output "hdc_status" {
  value = resource.uidai_mysql_replica.main.db.hdc.status
}

locals {
  current_is_replica = uidai_mysql_replica.main.db[var.current_location].status == null? false: true
  current_is_readonly = uidai_mysql_replica.main.db[var.current_location].status == null? true: false
}

output "current_db_not_writable" {
  value = local.current_is_replica || local.current_is_readonly
}

output "current_primary_location" {
  value = uidai_mysql_replica.main.current_primary_location
}