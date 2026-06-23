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
        {
            output_file = FILENAME suffix

            if (($1 == "src" || $1 == "src/gz") && NF >= 3) {
                source_name = $2

                if (source_name in first_source) {
                    if (!(FILENAME in changed_config)) {
                        print FILENAME >> changed_files
                        changed_config[FILENAME] = 1
                    }

                    print "# tailscale-opkg-preflight: fonte \"" source_name \
                          "\" duplicada; primeira declaração em " first_source[source_name] > output_file
                    print "# " $0 > output_file
                    next
                }

                first_source[source_name] = FILENAME ":" FNR
            }

            print $0 > output_file
        }
    ' "$@"

    if [ -s "$CHANGED_FILES" ]; then
        while IFS= read -r config_file; do
            backup_file="$config_file$OPKG_BACKUP_SUFFIX"

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
