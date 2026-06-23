#!/bin/sh
# Prepara o OPKG em firmwares OpenWrt que não criam /var/lock e remove
# declarações de feeds duplicadas sem alterar a fonte efetivamente usada.

set -eu

OPKG_LOCK_DIR="${OPKG_LOCK_DIR:-/var/lock}"
OPKG_MAIN_CONF="${OPKG_MAIN_CONF:-/etc/opkg.conf}"
OPKG_CONF_DIR="${OPKG_CONF_DIR:-/etc/opkg}"
OPKG_BACKUP_SUFFIX="${OPKG_BACKUP_SUFFIX:-.tailscale-backup}"
TEMP_ROOT="${TMPDIR:-/tmp}"
TEMP_SUFFIX=".tailscale-opkg-preflight.$$"
CHANGED_FILES="$TEMP_ROOT/tailscale-opkg-changed.$$"

cleanup() {
    rm -f "$CHANGED_FILES"
    [ ! -f "$OPKG_MAIN_CONF$TEMP_SUFFIX" ] || rm -f "$OPKG_MAIN_CONF$TEMP_SUFFIX"

    for config_file in "$OPKG_CONF_DIR"/*.conf; do
        [ -f "$config_file$TEMP_SUFFIX" ] || continue
        rm -f "$config_file$TEMP_SUFFIX"
    done
}

trap cleanup EXIT HUP INT TERM

echo "Preparando OPKG..."

if ! mkdir -p "$OPKG_LOCK_DIR"; then
    echo "ERRO: Não foi possível criar o diretório de lock: $OPKG_LOCK_DIR" >&2
    exit 1
fi

if [ ! -d "$OPKG_LOCK_DIR" ] || [ ! -w "$OPKG_LOCK_DIR" ]; then
    echo "ERRO: O diretório de lock do OPKG não existe ou não permite escrita: $OPKG_LOCK_DIR" >&2
    exit 1
fi

set --
[ ! -f "$OPKG_MAIN_CONF" ] || set -- "$@" "$OPKG_MAIN_CONF"

for config_file in "$OPKG_CONF_DIR"/*.conf; do
    [ -f "$config_file" ] || continue
    set -- "$@" "$config_file"
done

if [ "$#" -gt 0 ]; then
    rm -f "$CHANGED_FILES"
    for config_file in "$@"; do
        rm -f "$config_file$TEMP_SUFFIX"
    done

    awk -v suffix="$TEMP_SUFFIX" -v changed_files="$CHANGED_FILES" '
        function mark_changed(config_file) {
            if (!(config_file in changed_config)) {
                print config_file >> changed_files
                changed_config[config_file] = 1
            }
        }

        FNR == 1 && managed_marker {
            print marker_line > marker_output
            managed_marker = 0
        }

        {
            output_file = FILENAME suffix

            if ($0 ~ /^# tailscale-opkg-preflight:/) {
                marker_line = $0
                marker_output = output_file
                managed_marker = 1
                next
            }

            if (managed_marker) {
                if ($0 ~ /^#[[:space:]]+src(\/gz)?[[:space:]]+/) {
                    mark_changed(FILENAME)
                    sub(/^#[[:space:]]+/, "", $0)
                } else {
                    print marker_line > marker_output
                }

                managed_marker = 0
            }

            if (($1 == "src" || $1 == "src/gz") && NF >= 3) {
                source_name = $2
                source_url = $3

                if (source_url ~ /^https?:\/\/(www\.)?openwrt\.org\/?$/) {
                    mark_changed(FILENAME)
                    print "# tailscale-opkg-preflight: feed desativado; a URL não fornece um índice OPKG válido" > output_file
                    print "# " $0 > output_file
                    next
                }

                if (source_url ~ /^https?:\/\/downloads\.openwrt\.org\/releases\/[^/]+\/packages\/[^/]+\/lora\/?$/) {
                    mark_changed(FILENAME)
                    print "# tailscale-opkg-preflight: feed desativado; o repositório lora não existe nesta release" > output_file
                    print "# " $0 > output_file
                    next
                }

                if (source_name in first_source) {
                    mark_changed(FILENAME)

                    print "# tailscale-opkg-preflight: fonte \"" source_name \
                          "\" duplicada; primeira declaração em " first_source[source_name] > output_file
                    print "# " $0 > output_file
                    next
                }

                first_source[source_name] = FILENAME ":" FNR
            }

            print $0 > output_file
        }

        END {
            if (managed_marker) {
                print marker_line > marker_output
            }
        }
    ' "$@"

    if [ -s "$CHANGED_FILES" ]; then
        while IFS= read -r config_file; do
            backup_file="$config_file$OPKG_BACKUP_SUFFIX"

            if cmp -s "$config_file" "$config_file$TEMP_SUFFIX"; then
                rm -f "$config_file$TEMP_SUFFIX"
                continue
            fi

            if [ ! -e "$backup_file" ]; then
                cp -p "$config_file" "$backup_file"
            fi

            mv "$config_file$TEMP_SUFFIX" "$config_file"
            echo "Fonte duplicada desativada em: $config_file"
            echo "Backup preservado em: $backup_file"
        done < "$CHANGED_FILES"
    fi

    for config_file in "$@"; do
        [ ! -f "$config_file$TEMP_SUFFIX" ] || rm -f "$config_file$TEMP_SUFFIX"
    done
fi

echo "OPKG pronto."
