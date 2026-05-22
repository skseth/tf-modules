#!/bin/sh
# shellcheck disable=SC3028

dns_suffix="${1:?DNS suffix is required as the first argument}"
server_id_offset=${2:-0}
mysql_conf_dir="${3:-/etc/mysql/conf.d}"

pod_specific_file="${4:-$mysql_conf_dir/99-pod-specific.cnf}"
global_file="${5:-$mysql_conf_dir/01-global-config.cnf}"

server_id=$(( ${HOSTNAME##*-} + server_id_offset ))
report_host="${HOSTNAME}.${dns_suffix}"


cat <<-EOF > "$pod_specific_file" || exit 1
	[mysqld]
	plugin-load-add=group_replication.so
	server_id = ${server_id}
	report_host = "${report_host}"
EOF

cp /config/01-global-config.cnf "$global_file" || exit 1




