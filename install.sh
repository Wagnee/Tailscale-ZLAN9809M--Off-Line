#!/bin/bash
# Script de instalação do Tailscale para ZLAN9809M
# Execute este script no roteador ZLAN9809M
# Usa memória como buffer durante instalação

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
    echo "Usando memória como buffer temporário..."
    
    # Criar tmpfs na memória
    TMPDIR=/tmp/tailscale_install
    mkdir -p "$TMPDIR"
    mount -t tmpfs tmpfs "$TMPDIR" -o size=10M
    echo "Buffer de memória criado em $TMPDIR"
else
    TMPDIR=/tmp
fi

# Instalar dependências
echo "Instalando dependências..."
opkg update
opkg install kmod-tun ca-bundle ip-full xz

# Parar Tailscale se já estiver instalado
if [ -f /etc/init.d/tailscale ]; then
    echo "Parando Tailscale existente..."
    /etc/init.d/tailscale stop
    /etc/init.d/tailscale disable
fi

# Copiar IPK para buffer de memória
echo "Copiando pacote para buffer de memória..."
if [ -f ./tailscale-zlan9809m-core_*.ipk ]; then
    cp ./tailscale-zlan9809m-core_*.ipk "$TMPDIR/"
    echo "Pacote core copiado"
fi

if [ -f ./luci-app-tailscale-zlan9809m_*.ipk ]; then
    cp ./luci-app-tailscale-zlan9809m_*.ipk "$TMPDIR/"
    echo "Pacote LuCI copiado"
fi

# Instalar pacotes
echo "Instalando pacote core..."
opkg install "$TMPDIR"/tailscale-zlan9809m-core_*.ipk

echo "Instalando pacote LuCI (se disponível)..."
if [ -f "$TMPDIR"/luci-app-tailscale-zlan9809m_*.ipk ]; then
    opkg install "$TMPDIR"/luci-app-tailscale-zlan9809m_*.ipk
    /etc/init.d/uhttpd restart 2>/dev/null || true
fi

# Limpar buffer de memória
if [ "$TMPDIR" != "/tmp" ]; then
    echo "Limpando buffer de memória..."
    umount "$TMPDIR"
    rm -rf "$TMPDIR"
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
echo "1. Configure o Tailscale via CLI:"
echo "   uci set tailscale.@tailscale[0].enabled='1'"
echo "   uci set tailscale.@tailscale[0].auth_key='tskey-auth-SEU-KEY'"
echo "   uci set tailscale.@tailscale[0].advertise_routes='192.168.1.0/24'"
echo "   uci commit tailscale"
echo ""
echo "2. Inicie o serviço:"
echo "   /etc/init.d/tailscale start"
echo "   /etc/init.d/tailscale enable"
echo ""
echo "3. Se instalou LuCI, acesse: http://router-ip/cgi-bin/luci/admin/network/tailscale"
echo ""
echo "=========================================="
