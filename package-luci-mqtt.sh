#!/bin/bash
# Script para empacotar luci-app-mqtt como IPK

set -e

VERSION="1.0-1"
OUTPUT_DIR="$(pwd)/output"
BUILD_DIR="$(pwd)/package-luci-mqtt-build"

echo "=========================================="
echo "Empacotando luci-app-mqtt como IPK"
echo "=========================================="

# Limpar build anterior
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Criar estrutura do pacote
mkdir -p "${BUILD_DIR}/CONTROL"
mkdir -p "${BUILD_DIR}/usr/lib/lua/luci/controller/admin"
mkdir -p "${BUILD_DIR}/usr/lib/lua/luci/model/cbi"
mkdir -p "${BUILD_DIR}/usr/lib/lua/luci/view/mqtt"

# Copiar arquivos LuCI
cp luci/mqtt/luasrc/controller/admin/mqtt.lua "${BUILD_DIR}/usr/lib/lua/luci/controller/admin/"
cp luci/mqtt/luasrc/model/cbi/mqtt.lua "${BUILD_DIR}/usr/lib/lua/luci/model/cbi/"
cp luci/mqtt/luasrc/view/mqtt/status.htm "${BUILD_DIR}/usr/lib/lua/luci/view/mqtt/"

# Criar CONTROL/control
cat > "${BUILD_DIR}/CONTROL/control" <<EOF
Package: luci-app-mqtt
Version: ${VERSION}
Architecture: all
Maintainer: Tailscale for ZLAN9809M Project
Section: luci
Priority: optional
Description: LuCI interface for MQTT client daemon
Depends: luci-base, mqtt-daemon
Homepage: https://github.com/Wagnee/Tailscale-ZLAN9809M--Off-Line
License: MIT
EOF

# Criar CONTROL/postinst
cat > "${BUILD_DIR}/CONTROL/postinst" <<'EOF'
#!/bin/sh
/etc/init.d/uhttpd restart
EOF
chmod +x "${BUILD_DIR}/CONTROL/postinst"

# Criar IPK manualmente (tar.gz com estrutura IPK)
cd "${BUILD_DIR}"
tar -czf "${OUTPUT_DIR}/luci-app-mqtt_${VERSION}_mipsel_24kc.ipk" ./CONTROL ./usr

echo "=========================================="
echo "Pacote IPK criado!"
echo "=========================================="
ls -lh "${OUTPUT_DIR}/luci-app-mqtt_${VERSION}_mipsel_24kc.ipk"
