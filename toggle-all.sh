#!/bin/bash

# Usage: 
# ./toggle-all on
# ./toggle-all off

# @TODO: get rid of `sudo` usage

# Validate first parameter
if [[ $# -eq 0 ]]; then
    echo "Error: Missing parameter"
    echo "Usage: $0 [on|off]"
    exit 1
fi

case $1 in
    "on"|"off")
        # Valid parameter, continue execution
        ;;
    *)
        echo "Error: Invalid parameter '$1'"
        echo "Valid options: on | off"
        exit 1
        ;;
esac

cd /etc/nginx/sites-enabled

# Find all server names from server blocks that include maintenance-page.conf
find_server_names() {
cat * | awk '
    /^[ \t]*server[ \t]*\{/ { in_server=1; has_maintenance=0; server_names="" }
    in_server && !/^[ \t]*#/ && /maintenance-page\.conf/ { has_maintenance=1 }
    in_server && !/^[ \t]*#/ && /server_name/ { server_names = server_names (server_names ? " " : "") $0 }
    /^[ \t]*}/ && in_server { 
        if (has_maintenance && server_names != "") print server_names;
        in_server=0 
    }
' | sed 's/server_name//g' | tr -d ";" | cut -f1 -d"#" | xargs | tr " " "\n" | sort | uniq
}

# Main processing loop
while read -r server_name; do
    sudo ./maintenance.sh $server_name $1 batch-mode
done < <(find_server_names)

echo "Processing complete"
