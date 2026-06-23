#!/bin/bash
# Script para empacotar mosquitto-client como IPK

set -e

VERSION="2.0.18-1"
OUTPUT_DIR="$(pwd)/output"
BUILD_DIR="$(pwd)/package-mosquitto-build"

echo "=========================================="
echo "Empacotando mosquitto-client como IPK"
echo "=========================================="

# Limpar build anterior
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Criar estrutura do pacote
mkdir -p "${BUILD_DIR}/CONTROL"
mkdir -p "${BUILD_DIR}/usr/bin"

# Copiar binários se existirem
if [ -f "${OUTPUT_DIR}/mosquitto-client-${VERSION}-mipsel_24kc.tar.gz" ]; then
    tar -xzf "${OUTPUT_DIR}/mosquitto-client-${VERSION}-mipsel_24kc.tar.gz" -C "${BUILD_DIR}"
else
    echo "AVISO: Binários não encontrados, usando placeholder"
    mkdir -p "${BUILD_DIR}/usr/bin"
    touch "${BUILD_DIR}/usr/bin/mosquitto_pub"
    touch "${BUILD_DIR}/usr/bin/mosquitto_sub"
fi

# Criar CONTROL/control
cat > "${BUILD_DIR}/CONTROL/control" <<EOF
Package: mosquitto-client
Version: ${VERSION}
Architecture: mipsel_24kc
Maintainer: Tailscale for ZLAN9809M Project
Section: net
Priority: optional
Description: MQTT client binaries for ZLAN9809M
Homepage: https://github.com/eclipse/mosquitto
License: EPL-2.0
EOF

# Criar IPK
cd "${BUILD_DIR}"
ipkg-build -o root -g root . "${OUTPUT_DIR}"

echo "=========================================="
echo "Pacote IPK criado!"
echo "=========================================="
ls -lh "${OUTPUT_DIR}/mosquitto-client_${VERSION}_mipsel_24kc.ipk"
