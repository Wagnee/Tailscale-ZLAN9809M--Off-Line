#!/bin/bash
# Script para cross-compilar modbus-daemon para MIPS 24Kc (OpenWrt)
# Target: ZLAN9809M router

set -e

BUILD_DIR="$(pwd)/build-modbus-daemon"
OUTPUT_DIR="$(pwd)/output"
DAEMON_DIR="$(pwd)/modbus-daemon"
GO_VERSION="1.21.6"

echo "=========================================="
echo "Cross-compilando modbus-daemon para MIPS 24Kc"
echo "=========================================="
echo "Target: mipsel_24kc"
echo "=========================================="

# Limpar build anterior
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Baixar Go se não existir
GO_DIR="$(pwd)/go-${GO_VERSION}"
if [ ! -d "${GO_DIR}" ]; then
    echo "Baixando Go ${GO_VERSION}..."
    wget --no-check-certificate -O go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    tar -xf go.tar.gz
    mv go "${GO_DIR}"
    rm go.tar.gz
fi

# Configurar Go
export GOROOT="${GO_DIR}"
export PATH="${GOROOT}/bin:$PATH"
export GOPATH="${BUILD_DIR}/gopath"
mkdir -p "${GOPATH}"

# Baixar OpenWrt SDK se não existir
SDK_DIR="$(pwd)/openwrt-sdk"
if [ ! -d "${SDK_DIR}" ]; then
    echo "Baixando OpenWrt SDK..."
    wget --no-check-certificate -O openwrt-sdk.tar.xz "https://downloads.openwrt.org/releases/22.03.5/targets/ramips/mt76x8/OpenWrt-SDK-22.03.5-ramips-mt76x8_gcc-11.2.0_musl.Linux-x86_64.tar.xz"
    tar -xf openwrt-sdk.tar.xz
    mv OpenWrt-SDK-* "${SDK_DIR}"
    rm openwrt-sdk.tar.xz
fi

# Configurar toolchain
TOOLCHAIN="${SDK_DIR}/staging_dir/toolchain-mipsel_24kc_gcc-11.2.0_musl"
export PATH="${TOOLCHAIN}/bin:$PATH"

# Configurar cross-compilação Go
export CGO_ENABLED=1
export CC=mipsel-openwrt-linux-gcc
export CXX=mipsel-openwrt-linux-g++
export GOOS=linux
export GOARCH=mipsle
export GOMIPS=softfloat

# Copiar daemon para build
cp -r "${DAEMON_DIR}" "${BUILD_DIR}/modbus-daemon"
cd "${BUILD_DIR}/modbus-daemon"

# Baixar dependências
echo "Baixando dependências Go..."
go mod init modbus-daemon 2>/dev/null || true
go get github.com/goburrow/modbus@latest
go mod tidy

# Compilar
echo "Compilando modbus-daemon..."
go build -ldflags="-s -w" -o modbus-daemon .

# Verificar binário
if [ ! -f "modbus-daemon" ]; then
    echo "ERRO: Falha ao compilar modbus-daemon"
    exit 1
fi

# Mostrar tamanho antes da compressão
SIZE_BEFORE=$(ls -lh modbus-daemon | awk '{print $5}')
echo "Tamanho antes da compressão: ${SIZE_BEFORE}"

# Tentar compressão UPX se disponível
if command -v upx &> /dev/null; then
    echo "Comprimindo com UPX..."
    upx --best --lzma modbus-daemon
    SIZE_AFTER=$(ls -lh modbus-daemon | awk '{print $5}')
    echo "Tamanho após UPX: ${SIZE_AFTER}"
else
    echo "UPX não encontrado, pulando compressão"
fi

# Empacotar
echo "Empacotando..."
mkdir -p "${BUILD_DIR}/install/usr/bin"
cp modbus-daemon "${BUILD_DIR}/install/usr/bin/"
cd "${BUILD_DIR}/install"
tar -czf "${OUTPUT_DIR}/modbus-daemon-mipsel_24kc.tar.gz" usr

# Mostrar resultado
echo "=========================================="
echo "modbus-daemon compilado com sucesso!"
echo "=========================================="
echo "Arquivo: ${OUTPUT_DIR}/modbus-daemon-mipsel_24kc.tar.gz"
echo "Tamanho: $(ls -lh ${OUTPUT_DIR}/modbus-daemon-mipsel_24kc.tar.gz | awk '{print $5}')"
echo ""
echo "Conteúdo:"
tar -tzf "${OUTPUT_DIR}/modbus-daemon-mipsel_24kc.tar.gz"
echo ""
echo "=========================================="
