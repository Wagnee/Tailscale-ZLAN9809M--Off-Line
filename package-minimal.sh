#!/bin/bash
# Script para criar pacote IPK mínimo do Tailscale para OpenWrt (sem LuCI)

set -e

VERSION="1.68.1"
ARCH="mipsel_24kc"
PKG_NAME="tailscale-zlan9809m-minimal"
PKG_VERSION="${VERSION}-1"
OUTPUT_DIR="$(pwd)/output"
BUILD_DIR="$(pwd)/ipk-build"

echo "=========================================="
echo "Creating Minimal IPK Package (No LuCI)"
echo "=========================================="
echo "Package: ${PKG_NAME}"
echo "Version: ${PKG_VERSION}"
echo "Architecture: ${ARCH}"
echo "=========================================="

# Limpar build anterior
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Criar estrutura do pacote
mkdir -p "${BUILD_DIR}/control"
mkdir -p "${BUILD_DIR}/data/usr/sbin"
mkdir -p "${BUILD_DIR}/data/etc/config"
mkdir -p "${BUILD_DIR}/data/etc/init.d"
mkdir -p "${BUILD_DIR}/data/etc/hotplug.d/iface"
mkdir -p "${BUILD_DIR}/data/etc/uci-defaults"

# Copiar binário
if [ -f "${OUTPUT_DIR}/tailscaled" ]; then
    cp "${OUTPUT_DIR}/tailscaled" "${BUILD_DIR}/data/usr/sbin/tailscaled"
    chmod +x "${BUILD_DIR}/data/usr/sbin/tailscaled"
    ln -sf tailscaled "${BUILD_DIR}/data/usr/sbin/tailscale"
    echo "Binary copied: $(ls -lh ${BUILD_DIR}/data/usr/sbin/tailscaled | awk '{print $5}')"
else
    echo "ERRO: Binário não encontrado em ${OUTPUT_DIR}/tailscaled"
    echo "Execute ./build.sh primeiro"
    exit 1
fi

# Copiar arquivos de configuração (SEM LuCI)
if [ -f ./files/etc/config/tailscale ]; then
    cp ./files/etc/config/tailscale "${BUILD_DIR}/data/etc/config/tailscale"
fi

if [ -f ./files/etc/init.d/tailscale ]; then
    cp ./files/etc/init.d/tailscale "${BUILD_DIR}/data/etc/init.d/tailscale"
    chmod +x "${BUILD_DIR}/data/etc/init.d/tailscale"
fi

if [ -f ./files/etc/hotplug.d/iface/99-tailscale ]; then
    cp ./files/etc/hotplug.d/iface/99-tailscale "${BUILD_DIR}/data/etc/hotplug.d/iface/99-tailscale"
    chmod +x "${BUILD_DIR}/data/etc/hotplug.d/iface/99-tailscale"
fi

if [ -f ./files/etc/uci-defaults/99-tailscale ]; then
    cp ./files/etc/uci-defaults/99-tailscale "${BUILD_DIR}/data/etc/uci-defaults/99-tailscale"
    chmod +x "${BUILD_DIR}/data/etc/uci-defaults/99-tailscale"
fi

# Criar arquivo de controle
cat > "${BUILD_DIR}/control/control" <<EOF
Package: ${PKG_NAME}
Version: ${PKG_VERSION}
Architecture: ${ARCH}
Maintainer: Tailscale ZLAN9809M Project
Section: net
Priority: optional
Description: Tailscale VPN for ZLAN9809M (Minimal - No LuCI)
 Tailscale is a zero config VPN for building secure networks.
 This package is optimized for ZLAN9809M router with size constraints.
 Does not include LuCI web interface to save space.
Depends: kmod-tun, ca-bundle, ip-full
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
echo ""
echo "Para instalar no roteador:"
echo "1. Copie o arquivo .ipk para o roteador"
echo "2. Execute: opkg install ${PKG_NAME}_${PKG_VERSION}_${ARCH}.ipk"
echo ""
echo "Configuração via CLI:"
echo "uci set tailscale.@tailscale[0].enabled='1'"
echo "uci set tailscale.@tailscale[0].auth_key='tskey-auth-xxx'"
echo "uci set tailscale.@tailscale[0].advertise_routes='192.168.1.0/24'"
echo "uci commit tailscale"
echo "/etc/init.d/tailscale start"
echo "=========================================="
