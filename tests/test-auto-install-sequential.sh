#!/bin/bash

set -euo pipefail

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_ROOT="${TMPDIR:-/tmp}/tailscale-auto-install-test.$$"
FUNCTIONS_FILE="$TEST_ROOT/installer-functions.sh"
EVENTS_FILE="$TEST_ROOT/events.log"

cleanup() {
    rm -rf "$TEST_ROOT"
}

trap cleanup EXIT HUP INT TERM
mkdir -p "$TEST_ROOT"

awk '
    /^download_file\(\)/ { copying = 1 }
    /^# Corrigir feeds duplicados/ { copying = 0 }
    copying { print }
' "$PROJECT_DIR/auto_install.sh" > "$FUNCTIONS_FILE"

# shellcheck source=/dev/null
. "$FUNCTIONS_FILE"

REPO_URL="https://repository.example/main"
DOWNLOAD_TOOL="curl"

curl() {
    local output_file=""
    local source_url=""

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -o)
                output_file="$2"
                shift 2
                ;;
            http*)
                source_url="$1"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    printf 'fake ipk\n' > "$output_file"
    printf 'download:%s\n' "$source_url" >> "$EVENTS_FILE"
}

opkg() {
    [ "$1" = "install" ]
    printf 'install:%s\n' "$2" >> "$EVENTS_FILE"
}

cd "$TEST_ROOT"
install_remote_ipk "Pacote 1" "output/package-1.ipk" "package-1.ipk"
[ ! -e package-1.ipk ]

install_remote_ipk "Pacote 2" "output/package-2.ipk" "package-2.ipk"
[ ! -e package-2.ipk ]

expected_events='download:https://repository.example/main/output/package-1.ipk
install:./package-1.ipk
download:https://repository.example/main/output/package-2.ipk
install:./package-2.ipk'
actual_events=$(cat "$EVENTS_FILE")

[ "$actual_events" = "$expected_events" ]

echo "test-auto-install-sequential: OK"
