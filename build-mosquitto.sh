#!/bin/bash
# Script para cross-compilar mosquitto para MIPS 24Kc (OpenWrt)
# Target: ZLAN9809M router

set -e

VERSION="2.0.18"
BUILD_DIR="$(pwd)/build-mosquitto"
OUTPUT_DIR="$(pwd)/output"
TOOLCHAIN_URL="https://downloads.openwrt.org/releases/22.03.5/targets/ramips/mt76x8/OpenWrt-SDK-22.03.5-ramips-mt76x8_gcc-11.2.0_musl.Linux-x86_64.tar.xz"

echo "=========================================="
echo "Cross-compilando mosquitto para MIPS 24Kc"
echo "=========================================="
echo "Version: ${VERSION}"
echo "Target: mipsel_24kc"
echo "=========================================="

# Limpar build anterior
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Baixar OpenWrt SDK se não existir
SDK_DIR="$(pwd)/openwrt-sdk"
if [ ! -d "${SDK_DIR}" ]; then
    echo "Baixando OpenWrt SDK..."
    wget -O openwrt-sdk.tar.xz "${TOOLCHAIN_URL}"
    tar -xf openwrt-sdk.tar.xz
    mv OpenWrt-SDK-* "${SDK_DIR}"
    rm openwrt-sdk.tar.xz
fi

# Configurar toolchain
TOOLCHAIN="${SDK_DIR}/staging_dir/toolchain-mipsel_24kc_gcc-11.2.0_musl"
export PATH="${TOOLCHAIN}/bin:$PATH"
export CC=mipsel-openwrt-linux-gcc
export CXX=mipsel-openwrt-linux-g++
export AR=mipsel-openwrt-linux-ar
export RANLIB=mipsel-openwrt-linux-ranlib
export STRIP=mipsel-openwrt-linux-strip
export CFLAGS="-O2 -pipe -mno-branch-likely -mips32r2 -mtune=24kc"
export LDFLAGS="-s"

# Baixar mosquitto
echo "Baixando mosquitto ${VERSION}..."
cd "${BUILD_DIR}"
wget "https://github.com/eclipse/mosquitto/archive/refs/tags/v${VERSION}.tar.gz"
tar -xf "v${VERSION}.tar.gz"
cd "mosquitto-${VERSION}"

# Configurar
echo "Configurando mosquitto..."
cat > config.mk <<EOF
WITH_SRV=no
WITH_WEBSOCKETS=no
WITH_DOCS=no
WITH_SHARED_LIBRARIES=no
WITH_STATIC_LIBRARIES=no
WITH_CLIENTS=yes
WITH_BROKER=no
WITH_APPS=no
CFLAGS=-O2 -pipe -mno-branch-likely -mips32r2 -mtune=24kc
LDFLAGS=-s
CC=mipsel-openwrt-linux-gcc
CXX=mipsel-openwrt-linux-g++
AR=mipsel-openwrt-linux-ar
STRIP=mipsel-openwrt-linux-strip
EOF

# Compilar
echo "Compilando mosquitto..."
make -j$(nproc)

# Copiar binários
echo "Copiando binários..."
mkdir -p "${BUILD_DIR}/install/usr/bin"
cp client/mosquitto_pub "${BUILD_DIR}/install/usr/bin/"
cp client/mosquitto_sub "${BUILD_DIR}/install/usr/bin/"

# Strip binários
echo "Otimizando binários..."
mipsel-openwrt-linux-strip "${BUILD_DIR}/install/usr/bin/mosquitto_pub"
mipsel-openwrt-linux-strip "${BUILD_DIR}/install/usr/bin/mosquitto_sub"

# Empacotar
echo "Empacotando..."
cd "${BUILD_DIR}/install"
tar -czf "${OUTPUT_DIR}/mosquitto-client-${VERSION}-mipsel_24kc.tar.gz" usr

# Mostrar resultado
echo "=========================================="
echo "mosquitto compilado com sucesso!"
echo "=========================================="
echo "Arquivo: ${OUTPUT_DIR}/mosquitto-client-${VERSION}-mipsel_24kc.tar.gz"
echo "Tamanho: $(ls -lh ${OUTPUT_DIR}/mosquitto-client-${VERSION}-mipsel_24kc.tar.gz | awk '{print $5}')"
echo ""
echo "Conteúdo:"
tar -tzf "${OUTPUT_DIR}/mosquitto-client-${VERSION}-mipsel_24kc.tar.gz"
echo ""
echo "=========================================="
