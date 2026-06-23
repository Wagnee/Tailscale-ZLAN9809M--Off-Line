#!/bin/bash
# Script para criar pacote IPK da interface LuCI (opcional)

set -e

VERSION="1.68.1"
ARCH="mipsel_24kc"
PKG_NAME="luci-app-tailscale-zlan9809m"
PKG_VERSION="${VERSION}-1"
OUTPUT_DIR="$(pwd)/output"
BUILD_DIR="$(pwd)/ipk-build-luci"

echo "=========================================="
echo "Creating LuCI Interface Package"
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
mkdir -p "${BUILD_DIR}/data/usr/lib/lua/luci/controller/admin"
mkdir -p "${BUILD_DIR}/data/usr/lib/lua/luci/controller/admin"
mkdir -p "${BUILD_DIR}/data/usr/lib/lua/luci/model/cbi"
mkdir -p "${BUILD_DIR}/data/usr/lib/lua/luci/view/tailscale"

# Copiar arquivos LuCI
if [ -f ./luci/tailscale/luasrc/controller/admin/tailscale.lua ]; then
    cp ./luci/tailscale/luasrc/controller/admin/tailscale.lua "${BUILD_DIR}/data/usr/lib/lua/luci/controller/admin/tailscale.lua"
fi

if [ -f ./luci/tailscale/luasrc/controller/admin/tailscale_status.lua ]; then
    cp ./luci/tailscale/luasrc/controller/admin/tailscale_status.lua "${BUILD_DIR}/data/usr/lib/lua/luci/controller/admin/tailscale_status.lua"
fi

if [ -f ./luci/tailscale/luasrc/model/cbi/tailscale.lua ]; then
    cp ./luci/tailscale/luasrc/model/cbi/tailscale.lua "${BUILD_DIR}/data/usr/lib/lua/luci/model/cbi/tailscale.lua"
fi

if [ -f ./luci/tailscale/luasrc/view/tailscale/status.htm ]; then
    cp ./luci/tailscale/luasrc/view/tailscale/status.htm "${BUILD_DIR}/data/usr/lib/lua/luci/view/tailscale/status.htm"
fi

# Criar arquivo de controle
cat > "${BUILD_DIR}/control/control" <<EOF
Package: ${PKG_NAME}
Version: ${PKG_VERSION}
Architecture: ${ARCH}
Maintainer: Tailscale ZLAN9809M Project
Section: luci
Priority: optional
Depends: luci, tailscale-zlan9809m-core
Description: LuCI interface for Tailscale on ZLAN9809M
 Web interface for configuring Tailscale via LuCI.
 Install this package after the core package if you have space.
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
echo "LuCI IPK Package Created!"
echo "=========================================="
echo "File: ${OUTPUT_DIR}/${PKG_NAME}_${PKG_VERSION}_${ARCH}.ipk"
echo "Size: $(ls -lh ${OUTPUT_DIR}/${PKG_NAME}_${PKG_VERSION}_${ARCH}.ipk | awk '{print $5}')"
echo "=========================================="
echo ""
echo "Instalação:"
echo "1. Instale o pacote core primeiro"
echo "2. Depois instale este pacote LuCI se tiver espaço"
echo "=========================================="
