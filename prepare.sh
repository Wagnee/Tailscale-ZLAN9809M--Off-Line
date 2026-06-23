#!/bin/bash
# Script para preparar permissões dos scripts (execute no Linux/WSL2)

echo "Definindo permissões de execução..."

chmod +x build.sh
chmod +x install.sh
chmod +x package.sh
chmod +x files/etc/init.d/tailscale
chmod +x files/etc/hotplug.d/iface/99-tailscale
chmod +x files/etc/uci-defaults/99-tailscale

echo "Permissões definidas com sucesso!"
