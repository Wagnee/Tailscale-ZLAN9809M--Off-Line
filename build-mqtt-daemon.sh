#!/bin/bash
# Script para cross-compilar mqtt-daemon para MIPS 24Kc (OpenWrt)
# Target: ZLAN9809M router

set -e

BUILD_DIR="$(pwd)/build-mqtt-daemon"
OUTPUT_DIR="$(pwd)/output"
DAEMON_DIR="$(pwd)/mqtt-daemon"
GO_VERSION="1.24.0"

echo "=========================================="
echo "Cross-compilando mqtt-daemon para MIPS 24Kc"
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
    wget --no-check-certificate -O openwrt-sdk.tar.xz "https://archive.openwrt.org/releases/21.02.2/targets/ramips/mt76x8/openwrt-sdk-21.02.2-ramips-mt76x8_gcc-8.4.0_musl.Linux-x86_64.tar.xz"
    tar -xf openwrt-sdk.tar.xz
    # O nome do diretório extraído pode variar, usar ls para encontrar
    EXTRACTED_DIR=$(ls -d openwrt-sdk-* 2>/dev/null | head -n 1)
    if [ -n "$EXTRACTED_DIR" ]; then
        mv "$EXTRACTED_DIR" "${SDK_DIR}"
    else
        echo "ERRO: Diretório extraído não encontrado"
        exit 1
    fi
    rm openwrt-sdk.tar.xz
fi

# Configurar toolchain
TOOLCHAIN="${SDK_DIR}/staging_dir/toolchain-mipsel_24kc_gcc-8.4.0_musl"
export PATH="${TOOLCHAIN}/bin:$PATH"

# Configurar cross-compilação Go
export CGO_ENABLED=1
export CC=mipsel-openwrt-linux-gcc
export CXX=mipsel-openwrt-linux-g++
export GOOS=linux
export GOARCH=mipsle
export GOMIPS=softfloat

# Copiar daemon para build
cp -r "${DAEMON_DIR}" "${BUILD_DIR}/mqtt-daemon"
cd "${BUILD_DIR}/mqtt-daemon"

# Baixar dependências
echo "Baixando dependências Go..."
go mod init mqtt-daemon 2>/dev/null || true
go get github.com/eclipse/paho.mqtt.golang@latest
go mod tidy

# Compilar
echo "Compilando mqtt-daemon..."
go build -ldflags="-s -w" -o mqtt-daemon .

# Verificar binário
if [ ! -f "mqtt-daemon" ]; then
    echo "ERRO: Falha ao compilar mqtt-daemon"
    exit 1
fi

# Mostrar tamanho antes da compressão
SIZE_BEFORE=$(ls -lh mqtt-daemon | awk '{print $5}')
echo "Tamanho antes da compressão: ${SIZE_BEFORE}"

# Tentar compressão UPX se disponível
if command -v upx &> /dev/null; then
    echo "Comprimindo com UPX..."
    upx --best --lzma mqtt-daemon
    SIZE_AFTER=$(ls -lh mqtt-daemon | awk '{print $5}')
    echo "Tamanho após UPX: ${SIZE_AFTER}"
else
    echo "UPX não encontrado, pulando compressão"
fi

# Empacotar
echo "Empacotando..."
mkdir -p "${BUILD_DIR}/install/usr/bin"
cp mqtt-daemon "${BUILD_DIR}/install/usr/bin/"
cd "${BUILD_DIR}/install"
tar -czf "${OUTPUT_DIR}/mqtt-daemon-mipsel_24kc.tar.gz" usr

# Mostrar resultado
echo "=========================================="
echo "mqtt-daemon compilado com sucesso!"
echo "=========================================="
echo "Arquivo: ${OUTPUT_DIR}/mqtt-daemon-mipsel_24kc.tar.gz"
echo "Tamanho: $(ls -lh ${OUTPUT_DIR}/mqtt-daemon-mipsel_24kc.tar.gz | awk '{print $5}')"
echo ""
echo "Conteúdo:"
tar -tzf "${OUTPUT_DIR}/mqtt-daemon-mipsel_24kc.tar.gz"
echo ""
echo "=========================================="
