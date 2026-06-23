#!/bin/bash
# Script para empacotar mqtt-daemon como IPK

set -e

VERSION="1.0-1"
OUTPUT_DIR="$(pwd)/output"
BUILD_DIR="$(pwd)/package-mqtt-build"

echo "=========================================="
echo "Empacotando mqtt-daemon como IPK"
echo "=========================================="

# Limpar build anterior
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Criar estrutura do pacote
mkdir -p "${BUILD_DIR}/CONTROL"
mkdir -p "${BUILD_DIR}/usr/bin"
mkdir -p "${BUILD_DIR}/etc/init.d"
mkdir -p "${BUILD_DIR}/etc/config"

# Copiar binário se existir
if [ -f "${OUTPUT_DIR}/mqtt-daemon-mipsel_24kc.tar.gz" ]; then
    tar -xzf "${OUTPUT_DIR}/mqtt-daemon-mipsel_24kc.tar.gz" -C "${BUILD_DIR}"
else
    echo "ERRO: Binário não encontrado em ${OUTPUT_DIR}/mqtt-daemon-mipsel_24kc.tar.gz"
    exit 1
fi

# Copiar script de init
cp files/etc/init.d/mqtt-daemon "${BUILD_DIR}/etc/init.d/"
chmod +x "${BUILD_DIR}/etc/init.d/mqtt-daemon"

# Copiar configuração
cp files/etc/config/mqtt "${BUILD_DIR}/etc/config/"

# Criar CONTROL/control
cat > "${BUILD_DIR}/CONTROL/control" <<EOF
Package: mqtt-daemon
Version: ${VERSION}
Architecture: mipsel_24kc
Maintainer: Tailscale for ZLAN9809M Project
Section: base
Priority: optional
Description: MQTT client daemon for ZLAN9809M
Depends: mosquitto-client
Homepage: https://github.com/Wagnee/Tailscale-ZLAN9809M--Off-Line
License: MIT
EOF

# Criar CONTROL/postinst
cat > "${BUILD_DIR}/CONTROL/postinst" <<'EOF'
#!/bin/sh
chmod +x /etc/init.d/mqtt-daemon
EOF
chmod +x "${BUILD_DIR}/CONTROL/postinst"

# Criar CONTROL/prerm
cat > "${BUILD_DIR}/CONTROL/prerm" <<'EOF'
#!/bin/sh
/etc/init.d/mqtt-daemon stop
EOF
chmod +x "${BUILD_DIR}/CONTROL/prerm"

# Criar IPK manualmente (tar.gz com estrutura IPK)
cd "${BUILD_DIR}"
tar -czf "${OUTPUT_DIR}/mqtt-daemon_${VERSION}_mipsel_24kc.ipk" ./CONTROL ./usr ./etc

echo "=========================================="
echo "Pacote IPK criado!"
echo "=========================================="
ls -lh "${OUTPUT_DIR}/mqtt-daemon_${VERSION}_mipsel_24kc.ipk"
