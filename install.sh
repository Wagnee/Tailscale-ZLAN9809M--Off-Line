#!/bin/bash
# Script de instalação do Tailscale para ZLAN9809M
# Execute este script no roteador ZLAN9809M

set -e

echo "=========================================="
echo "Tailscale Installer for ZLAN9809M"
echo "=========================================="

# Verificar se está rodando no roteador
if [ ! -f /etc/openwrt_release ]; then
    echo "ERRO: Este script deve ser executado no roteador OpenWrt"
    exit 1
fi

# Verificar arquitetura
ARCH=$(uname -m)
echo "Arquitetura detectada: $ARCH"

if [ "$ARCH" != "mips" ]; then
    echo "AVISO: Arquitetura não é MIPS. Continuando mesmo assim..."
fi

# Verificar espaço disponível
AVAILABLE_SPACE=$(df -m /overlay | awk 'NR==2 {print $4}')
echo "Espaço disponível: ${AVAILABLE_SPACE}MB"

if [ "$AVAILABLE_SPACE" -lt 5 ]; then
    echo "ERRO: Espaço insuficiente. Necessário pelo menos 5MB"
    exit 1
fi

# Instalar dependências
echo "Instalando dependências..."
opkg update
opkg install kmod-tun ca-bundle ip-full ipset ipset6

# Parar Tailscale se já estiver instalado
if [ -f /etc/init.d/tailscale ]; then
    echo "Parando Tailscale existente..."
    /etc/init.d/tailscale stop
    /etc/init.d/tailscale disable
fi

# Criar diretórios
echo "Criando diretórios..."
mkdir -p /usr/sbin
mkdir -p /etc/tailscale
mkdir -p /etc/config
mkdir -p /etc/init.d
mkdir -p /etc/hotplug.d/iface
mkdir -p /etc/uci-defaults

# Copiar binário
echo "Copiando binário tailscaled..."
cp ./output/tailscaled /usr/sbin/tailscaled
chmod +x /usr/sbin/tailscaled

ln -sf /usr/sbin/tailscaled /usr/sbin/tailscale

# Copiar arquivos de configuração
echo "Copiando arquivos de configuração..."
if [ -f ./files/etc/config/tailscale ]; then
    cp ./files/etc/config/tailscale /etc/config/tailscale
fi

if [ -f ./files/etc/init.d/tailscale ]; then
    cp ./files/etc/init.d/tailscale /etc/init.d/tailscale
    chmod +x /etc/init.d/tailscale
fi

if [ -f ./files/etc/hotplug.d/iface/99-tailscale ]; then
    cp ./files/etc/hotplug.d/iface/99-tailscale /etc/hotplug.d/iface/99-tailscale
    chmod +x /etc/hotplug.d/iface/99-tailscale
fi

if [ -f ./files/etc/uci-defaults/99-tailscale ]; then
    cp ./files/etc/uci-defaults/99-tailscale /etc/uci-defaults/99-tailscale
    chmod +x /etc/uci-defaults/99-tailscale
fi

# Instalar interface LuCI (se existir)
if [ -d ./luci ]; then
    echo "Instalando interface LuCI..."
    
    # Criar diretórios LuCI
    mkdir -p /usr/lib/lua/luci/controller/admin
    mkdir -p /usr/lib/lua/luci/model/cbi
    mkdir -p /usr/lib/lua/luci/view/tailscale
    
    # Copiar arquivos
    if [ -f ./luci/tailscale/luasrc/controller/admin/tailscale.lua ]; then
        cp ./luci/tailscale/luasrc/controller/admin/tailscale.lua /usr/lib/lua/luci/controller/admin/tailscale.lua
    fi
    
    if [ -f ./luci/tailscale/luasrc/controller/admin/tailscale_status.lua ]; then
        cp ./luci/tailscale/luasrc/controller/admin/tailscale_status.lua /usr/lib/lua/luci/controller/admin/tailscale_status.lua
    fi
    
    if [ -f ./luci/tailscale/luasrc/model/cbi/tailscale.lua ]; then
        cp ./luci/tailscale/luasrc/model/cbi/tailscale.lua /usr/lib/lua/luci/model/cbi/tailscale.lua
    fi
    
    if [ -f ./luci/tailscale/luasrc/view/tailscale/status.htm ]; then
        cp ./luci/tailscale/luasrc/view/tailscale/status.htm /usr/lib/lua/luci/view/tailscale/status.htm
    fi
    
    # Reiniciar LuCI
    /etc/init.d/uhttpd restart 2>/dev/null || true
fi

# Executar uci-defaults
echo "Executando configurações padrão..."
for script in /etc/uci-defaults/*; do
    [ -f "$script" ] && "$script"
done

echo "=========================================="
echo "Instalação concluída!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo "1. Configure o Tailscale via LuCI: http://router-ip/cgi-bin/luci/admin/network/tailscale"
echo "   ou via CLI:"
echo "   uci set tailscale.@tailscale[0].enabled='1'"
echo "   uci set tailscale.@tailscale[0].auth_key='tskey-auth-SEU-KEY'"
echo "   uci set tailscale.@tailscale[0].advertise_routes='192.168.1.0/24'"
echo "   uci commit tailscale"
echo ""
echo "2. Inicie o serviço:"
echo "   /etc/init.d/tailscale start"
echo "   /etc/init.d/tailscale enable"
echo ""
echo "=========================================="
