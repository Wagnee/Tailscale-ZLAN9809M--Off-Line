#!/bin/bash
# Script para empacotar libmodbus como IPK

set -e

VERSION="3.1.10-1"
OUTPUT_DIR="$(pwd)/output"
BUILD_DIR="$(pwd)/package-libmodbus-build"

echo "=========================================="
echo "Empacotando libmodbus como IPK"
echo "=========================================="

# Limpar build anterior
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Criar estrutura do pacote
mkdir -p "${BUILD_DIR}/CONTROL"
mkdir -p "${BUILD_DIR}/usr/lib"

# Copiar biblioteca se existir
if [ -f "${OUTPUT_DIR}/libmodbus-${VERSION}-mipsel_24kc.tar.gz" ]; then
    tar -xzf "${OUTPUT_DIR}/libmodbus-${VERSION}-mipsel_24kc.tar.gz" -C "${BUILD_DIR}"
else
    echo "AVISO: Biblioteca não encontrada, usando placeholder"
    mkdir -p "${BUILD_DIR}/usr/lib"
    touch "${BUILD_DIR}/usr/lib/libmodbus.so.5"
fi

# Criar CONTROL/control
cat > "${BUILD_DIR}/CONTROL/control" <<EOF
Package: libmodbus
Version: ${VERSION}
Architecture: mipsel_24kc
Maintainer: Tailscale for ZLAN9809M Project
Section: libs
Priority: optional
Description: Modbus library for ZLAN9809M
Homepage: https://github.com/stephane/libmodbus
License: LGPL-2.1
EOF

# Criar IPK
cd "${BUILD_DIR}"
ipkg-build -o root -g root . "${OUTPUT_DIR}"

echo "=========================================="
echo "Pacote IPK criado!"
echo "=========================================="
ls -lh "${OUTPUT_DIR}/libmodbus_${VERSION}_mipsel_24kc.ipk"
