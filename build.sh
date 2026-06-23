#!/bin/bash
# Script de compilação do Tailscale para ZLAN9809M (MIPS 24Kc)
# Otimizado para tamanho (< 4MB após compressão UPX)

set -e

# Configurações
TAILSCALE_VERSION="1.68.1"
BUILD_DIR="$(pwd)/build"
OUTPUT_DIR="$(pwd)/output"
TAILSCALE_DIR="${BUILD_DIR}/tailscale"

# Arquitetura alvo (MT7628NN = mipsel_24kc)
GOOS="linux"
GOARCH="mipsle"
GOMIPS="softfloat"

# Flags de compilação otimizadas
BUILD_TAGS="ts_include_cli,ts_omit_aws,ts_omit_bird,ts_omit_completion,ts_omit_kube,ts_omit_systray,ts_omit_taildrop,ts_omit_tap,ts_omit_tpm,ts_omit_relayserver,ts_omit_capture,ts_omit_syspolicy,ts_omit_debugeventbus,ts_omit_webclient"
LDFLAGS="-s -w -buildid="

echo "=========================================="
echo "Tailscale Build Script for ZLAN9809M"
echo "=========================================="
echo "Versão: ${TAILSCALE_VERSION}"
echo "Arquitetura: ${GOARCH} (${GOMIPS})"
echo "=========================================="

# Limpar diretórios anteriores
rm -rf "${BUILD_DIR}" "${OUTPUT_DIR}"
mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"

# Verificar dependências
echo "Verificando dependências..."
command -v go >/dev/null 2>&1 || { echo "Go não encontrado. Instale Go 1.21+"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Git não encontrado. Instale Git"; exit 1; }
command -v upx >/dev/null 2>&1 || { echo "UPX não encontrado. Instale UPX para compressão"; exit 1; }

# Baixar código fonte do Tailscale
echo "Baixando Tailscale v${TAILSCALE_VERSION}..."
cd "${BUILD_DIR}"
git clone https://github.com/tailscale/tailscale.git
cd tailscale
git checkout tags/v${TAILSCALE_VERSION} -b v${TAILSCALE_VERSION}

# Compilar Tailscale
echo "Compilando Tailscale para ${GOARCH}..."
export GOOS=${GOOS}
export GOARCH=${GOARCH}
export GOMIPS=${GOMIPS}
export CGO_ENABLED=0

go build \
    -o tailscale.combined \
    -tags "${BUILD_TAGS}" \
    -trimpath \
    -ldflags "${LDFLAGS}" \
    ./cmd/tailscaled

echo "Binário compilado: $(ls -lh tailscale.combined | awk '{print $5}')"

# Strip do binário (se disponível)
if command -v mipsel-linux-gnu-strip >/dev/null 2>&1; then
    echo "Aplicando strip..."
    mipsel-linux-gnu-strip tailscale.combined
    echo "Após strip: $(ls -lh tailscale.combined | awk '{print $5}')"
fi

# Comprimir com UPX
echo "Comprimindo com UPX..."
upx --lzma --best --overlay=copy tailscale.combined
echo "Após UPX: $(ls -lh tailscale.combined | awk '{print $5}')"

# Copiar para diretório de output
cp tailscale.combined "${OUTPUT_DIR}/tailscaled"
chmod +x "${OUTPUT_DIR}/tailscaled"

# Criar symlinks
cd "${OUTPUT_DIR}"
ln -sf tailscaled tailscale

echo "=========================================="
echo "Build concluído com sucesso!"
echo "=========================================="
echo "Binário: ${OUTPUT_DIR}/tailscaled"
echo "Tamanho: $(ls -lh ${OUTPUT_DIR}/tailscaled | awk '{print $5}')"
echo "=========================================="
