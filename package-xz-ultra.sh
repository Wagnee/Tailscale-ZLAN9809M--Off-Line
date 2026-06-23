#!/bin/bash
# Script para criar pacote IPK ultra-minimal do Tailscale com binário xz comprimido

set -e

VERSION="1.68.1"
ARCH="mipsel_24kc"
PKG_NAME="tailscale-zlan9809m-core"
PKG_VERSION="${VERSION}-1"
OUTPUT_DIR="$(pwd)/output"
BUILD_DIR="$(pwd)/ipk-build"

echo "=========================================="
echo "Creating Ultra-Minimal IPK Package (XZ Compressed)"
echo "=========================================="
echo "Package: ${PKG_NAME}"
echo "Version: ${PKG_VERSION}"
echo "Architecture: ${ARCH}"
echo "=========================================="

# Limpar build anterior
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Criar estrutura do pacote (apenas essencial - sem hotplug, sem uci-defaults)
mkdir -p "${BUILD_DIR}/control"
mkdir -p "${BUILD_DIR}/data/usr/sbin"
mkdir -p "${BUILD_DIR}/data/etc/config"
mkdir -p "${BUILD_DIR}/data/etc/init.d"

# Copiar binário xz comprimido
if [ -f "${OUTPUT_DIR}/tailscaled.xz" ]; then
    cp "${OUTPUT_DIR}/tailscaled.xz" "${BUILD_DIR}/data/usr/sbin/tailscaled.xz"
    echo "Binary copied: $(ls -lh ${BUILD_DIR}/data/usr/sbin/tailscaled.xz | awk '{print $5}')"
else
    echo "ERRO: Binário não encontrado em ${OUTPUT_DIR}/tailscaled.xz"
    exit 1
fi

# Copiar apenas configuração essencial
if [ -f ./files/etc/config/tailscale ]; then
    cp ./files/etc/config/tailscale "${BUILD_DIR}/data/etc/config/tailscale"
fi

# Script de init simplificado
cat > "${BUILD_DIR}/data/etc/init.d/tailscale" <<'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10
USE_PROCD=1

PROG=/usr/sbin/tailscaled
STATE_DIR=/etc/tailscale

start_service() {
    local enabled auth_key accept_routes accept_dns advertise_routes
    
    config_load 'tailscale'
    config_get enabled 'tailscale' 'enabled' '0'
    config_get auth_key 'tailscale' 'auth_key' ''
    config_get accept_routes 'tailscale' 'accept_routes' '1'
    config_get accept_dns 'tailscale' 'accept_dns' '1'
    config_get advertise_routes 'tailscale' 'advertise_routes' ''
    
    [ "$enabled" = "1" ] || return 0
    
    mkdir -p "$STATE_DIR"
    [ -d /sys/module/tun ] || modprobe tun
    
    local args="--state=$STATE_DIR/tailscale.state --socket=$STATE_DIR/tailscaled.sock"
    [ "$accept_routes" = "1" ] && args="$args --accept-routes"
    [ "$accept_dns" = "1" ] && args="$args --accept-dns"
    
    procd_open_instance
    procd_set_param command "$PROG" $args
    procd_set_param pidfile "$STATE_DIR/tailscaled.pid"
    procd_set_param respawn
    procd_close_instance
    
    sleep 2
    
    if [ -n "$auth_key" ]; then
        local connect_args=""
        [ -n "$advertise_routes" ] && connect_args="$connect_args --advertise-routes=$advertise_routes"
        /usr/sbin/tailscale up --authkey="$auth_key" $connect_args
    fi
}

stop_service() {
    /usr/sbin/tailscale down 2>/dev/null || true
    procd_kill tailscale
}
EOF
chmod +x "${BUILD_DIR}/data/etc/init.d/tailscale"

# Script de init simplificado com descompressão integrada
cat > "${BUILD_DIR}/data/etc/init.d/tailscale" <<'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10
USE_PROCD=1

PROG=/usr/sbin/tailscaled
STATE_DIR=/etc/tailscale

# Descomprimir binário se necessário
decompress_binary() {
    if [ -f /usr/sbin/tailscaled.xz ] && [ ! -f /usr/sbin/tailscaled ]; then
        echo "Descomprimindo Tailscale..."
        xz -d /usr/sbin/tailscaled.xz
        chmod +x /usr/sbin/tailscaled
        ln -sf tailscaled /usr/sbin/tailscale
        echo "Tailscale descomprimido!"
    fi
}

start_service() {
    local enabled auth_key accept_routes accept_dns advertise_routes
    
    decompress_binary
    
    config_load 'tailscale'
    config_get enabled 'tailscale' 'enabled' '0'
    config_get auth_key 'tailscale' 'auth_key' ''
    config_get accept_routes 'tailscale' 'accept_routes' '1'
    config_get accept_dns 'tailscale' 'accept_dns' '1'
    config_get advertise_routes 'tailscale' 'advertise_routes' ''
    
    [ "$enabled" = "1" ] || return 0
    
    mkdir -p "$STATE_DIR"
    [ -d /sys/module/tun ] || modprobe tun
    
    local args="--state=$STATE_DIR/tailscale.state --socket=$STATE_DIR/tailscaled.sock"
    [ "$accept_routes" = "1" ] && args="$args --accept-routes"
    [ "$accept_dns" = "1" ] && args="$args --accept-dns"
    
    procd_open_instance
    procd_set_param command "$PROG" $args
    procd_set_param pidfile "$STATE_DIR/tailscaled.pid"
    procd_set_param respawn
    procd_close_instance
    
    sleep 2
    
    if [ -n "$auth_key" ]; then
        local connect_args=""
        [ -n "$advertise_routes" ] && connect_args="$connect_args --advertise-routes=$advertise_routes"
        /usr/sbin/tailscale up --authkey="$auth_key" $connect_args
    fi
}

stop_service() {
    /usr/sbin/tailscale down 2>/dev/null || true
    procd_kill tailscale
}
EOF
chmod +x "${BUILD_DIR}/data/etc/init.d/tailscale"

# Criar arquivo de controle
cat > "${BUILD_DIR}/control/control" <<EOF
Package: ${PKG_NAME}
Version: ${PKG_VERSION}
Architecture: ${ARCH}
Maintainer: Tailscale ZLAN9809M Project
Section: net
Priority: optional
Description: Tailscale VPN for ZLAN9809M (Core - 4.5MB)
 Tailscale is a zero config VPN for building secure networks.
 Ultra-minimal package with XZ compression.
 Binary is decompressed on first boot.
Depends: kmod-tun, ca-bundle, xz
EOF

# Criar debian-binary
echo "2.0" > "${BUILD_DIR}/debian-binary"

# Empacotar
cd "${BUILD_DIR}"

echo "Creating data.tar.gz..."
tar --numeric-owner --owner=0 --group=0 -czf data.tar.gz -C data .

echo "Creating control.tar.gz..."
tar --numeric-owner --owner=0 --group=0 -czf control.tar.gz -C control .

echo "Creating IPK package..."
ar r "${OUTPUT_DIR}/${PKG_NAME}_${PKG_VERSION}_${ARCH}.ipk" debian-binary data.tar.gz control.tar.gz

cd ..

# Limpar
rm -rf "${BUILD_DIR}"

echo "=========================================="
echo "IPK Package Created!"
echo "=========================================="
echo "File: ${OUTPUT_DIR}/${PKG_NAME}_${PKG_VERSION}_${ARCH}.ipk"
echo "Size: $(ls -lh ${OUTPUT_DIR}/${PKG_NAME}_${PKG_VERSION}_${ARCH}.ipk | awk '{print $5}')"
echo "=========================================="
