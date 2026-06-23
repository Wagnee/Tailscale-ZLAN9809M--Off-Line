#!/bin/sh

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_ROOT="${TMPDIR:-/tmp}/tailscale-opkg-test.$$"
TEST_SHELL="${TEST_SHELL:-sh}"

cleanup() {
    rm -rf "$TEST_ROOT"
}

trap cleanup EXIT HUP INT TERM

mkdir -p "$TEST_ROOT/etc/opkg"

cat > "$TEST_ROOT/etc/opkg.conf" <<'EOF'
dest root /
src/gz openwrt_core https://downloads.openwrt.org/core-first
EOF

cat > "$TEST_ROOT/etc/opkg/distfeeds.conf" <<'EOF'
src/gz openwrt_base https://downloads.openwrt.org/base
src openwrt_core https://downloads.openwrt.org/core-duplicate
EOF

cat > "$TEST_ROOT/etc/opkg/customfeeds.conf" <<'EOF'
src/gz vendor_packages https://vendor.example/packages
src/gz vendor_packages https://vendor.example/packages-duplicate
EOF

OPKG_LOCK_DIR="$TEST_ROOT/var/lock" \
OPKG_MAIN_CONF="$TEST_ROOT/etc/opkg.conf" \
OPKG_CONF_DIR="$TEST_ROOT/etc/opkg" \
OPKG_BACKUP_SUFFIX=".test-backup" \
"$TEST_SHELL" "$PROJECT_DIR/opkg-preflight.sh"

[ -d "$TEST_ROOT/var/lock" ]
[ -f "$TEST_ROOT/etc/opkg/distfeeds.conf.test-backup" ]
[ -f "$TEST_ROOT/etc/opkg/customfeeds.conf.test-backup" ]

grep -q '^src/gz openwrt_core https://downloads.openwrt.org/core-first$' \
    "$TEST_ROOT/etc/opkg.conf"
grep -q '^# src openwrt_core https://downloads.openwrt.org/core-duplicate$' \
    "$TEST_ROOT/etc/opkg/distfeeds.conf"
grep -q '^# src/gz vendor_packages https://vendor.example/packages-duplicate$' \
    "$TEST_ROOT/etc/opkg/customfeeds.conf"

before_second_run=$(cksum "$TEST_ROOT/etc/opkg/distfeeds.conf")

OPKG_LOCK_DIR="$TEST_ROOT/var/lock" \
OPKG_MAIN_CONF="$TEST_ROOT/etc/opkg.conf" \
OPKG_CONF_DIR="$TEST_ROOT/etc/opkg" \
OPKG_BACKUP_SUFFIX=".test-backup" \
"$TEST_SHELL" "$PROJECT_DIR/opkg-preflight.sh"

after_second_run=$(cksum "$TEST_ROOT/etc/opkg/distfeeds.conf")
[ "$before_second_run" = "$after_second_run" ]

echo "test-opkg-preflight: OK"
