#!/bin/bash
# Script para empacotar luci-app-modbus como IPK

set -e

VERSION="1.0-1"
OUTPUT_DIR="$(pwd)/output"
BUILD_DIR="$(pwd)/package-luci-modbus-build"

echo "=========================================="
echo "Empacotando luci-app-modbus como IPK"
echo "=========================================="

# Limpar build anterior
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Criar estrutura do pacote
mkdir -p "${BUILD_DIR}/CONTROL"
mkdir -p "${BUILD_DIR}/usr/lib/lua/luci/controller/admin"
mkdir -p "${BUILD_DIR}/usr/lib/lua/luci/model/cbi"
mkdir -p "${BUILD_DIR}/usr/lib/lua/luci/view/modbus"

# Copiar arquivos LuCI
cp luci/modbus/luasrc/controller/admin/modbus.lua "${BUILD_DIR}/usr/lib/lua/luci/controller/admin/"
cp luci/modbus/luasrc/model/cbi/modbus.lua "${BUILD_DIR}/usr/lib/lua/luci/model/cbi/"
cp luci/modbus/luasrc/view/modbus/status.htm "${BUILD_DIR}/usr/lib/lua/luci/view/modbus/"

# Criar CONTROL/control
cat > "${BUILD_DIR}/CONTROL/control" <<EOF
Package: luci-app-modbus
Version: ${VERSION}
Architecture: all
Maintainer: Tailscale for ZLAN9809M Project
Section: luci
Priority: optional
Description: LuCI interface for Modbus TCP daemon
Depends: luci-base, modbus-daemon
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
tar -czf "${OUTPUT_DIR}/luci-app-modbus_${VERSION}_mipsel_24kc.ipk" ./CONTROL ./usr

echo "=========================================="
echo "Pacote IPK criado!"
echo "=========================================="
ls -lh "${OUTPUT_DIR}/luci-app-modbus_${VERSION}_mipsel_24kc.ipk"
