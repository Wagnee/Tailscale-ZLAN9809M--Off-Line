#!/bin/bash
# install-auto-update-daemon.sh - Instala o daemon de auto-update com whitelist

set -e

echo "=========================================="
echo "Instalando Daemon de Auto-Update"
echo "=========================================="
echo ""

# Criar diretório para scripts
SCRIPTS_DIR="/usr/lib/auto-update"
mkdir -p "$SCRIPTS_DIR"

# Copiar scripts
echo "Copiando scripts..."
cp auto-update-daemon.sh "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/auto-update-daemon.sh"

# Copiar whitelist
echo "Copiando whitelist..."
cp auto-update-whitelist.conf /etc/
chmod 644 /etc/auto-update-whitelist.conf

# Criar diretório para hashes
mkdir -p /var/lib/auto-update-executed

# Criar init script
echo "Criando init script..."
cat > /etc/init.d/auto-update <<'EOF'
#!/bin/sh /etc/rc.common
# Copyright 2024 Tailscale for ZLAN9809M Project
# Licensed under MIT License

USE_PROCD=1
START=99
STOP=10

start_service() {
    procd_open_instance
    procd_set_param command /usr/lib/auto-update/auto-update-daemon.sh
    procd_set_param respawn
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

stop_service() {
    killall auto-update-daemon.sh 2>/dev/null
}
EOF
chmod +x /etc/init.d/auto-update

# Habilitar daemon
echo "Habilitando daemon..."
/etc/init.d/auto-update enable

echo ""
echo "=========================================="
echo "Instalação concluída!"
echo "=========================================="
echo ""
echo "Para iniciar o daemon:"
echo "  /etc/init.d/auto-update start"
echo ""
echo "Para verificar status:"
echo "  /etc/init.d/auto-update status"
echo ""
echo "Logs:"
echo "  tail -f /var/log/auto-update-daemon.log"
echo ""
echo "Whitelist:"
echo "  cat /etc/auto-update-whitelist.conf"
echo ""
