#!/bin/bash
# Script Master de Instalação Automática - Tailscale para ZLAN9809M
# Executa tudo automaticamente: limpeza, instalação e configuração
# Uso: curl -L https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main/auto_install.sh | bash
# Ou: wget -O- https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main/auto_install.sh | bash

set -e

echo "=========================================="
echo "Instalação Automática - Tailscale ZLAN9809M"
echo "=========================================="
echo ""

# Detectar se está rodando no roteador
if [ ! -f /etc/openwrt_release ]; then
    echo "ERRO: Este script deve ser executado no roteador OpenWrt"
    echo "Execute via SSH no roteador ou use os scripts manualmente"
    exit 1
fi

# Mostrar especificações do hardware
echo "=========================================="
echo "Especificações do Hardware - ZLAN9809M"
echo "=========================================="
echo "Processador: MediaTek MT7628NN (MIPS 24Kc, 580MHz)"
echo "Arquitetura: $(uname -m)"
echo "Cores: $(nproc)"
echo "RAM Total: $(free -m | grep Mem | awk '{print $2}')MB"
echo "Flash Total: $(df -m / | awk 'NR==2 {print $2}')MB"
echo ""

# Mostrar estado ANTES
echo "=========================================="
echo "Estado ANTES das Modificações"
echo "=========================================="
echo "Espaço em /overlay (flash):"
df -h /overlay
echo ""
echo "Uso de RAM:"
free -h
echo ""
echo "Pacotes instalados: $(opkg list-installed | wc -l)"
echo ""

# Criar diretório temporário
TMPDIR="/tmp/tailscale_auto_install"
mkdir -p "$TMPDIR"
cd "$TMPDIR"

# Baixar scripts necessários
echo "=========================================="
echo "Baixando scripts..."
echo "=========================================="
REPO_URL="https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main"

# Baixar cleanup.sh
echo "Baixando cleanup.sh..."
curl -L "$REPO_URL/cleanup.sh" -o cleanup.sh
chmod +x cleanup.sh

# Baixar pacotes IPK (se disponíveis no repositório)
echo "Baixando pacotes IPK..."
curl -L "$REPO_URL/output/tailscale-zlan9809m-core_1.68.1-1_mipsel_24kc.ipk" -o tailscale-core.ipk || echo "Pacote core não encontrado no repositório"
curl -L "$REPO_URL/output/luci-app-tailscale-zlan9809m_1.68.1-1_mipsel_24kc.ipk" -o tailscale-luci.ipk || echo "Pacote LuCI não encontrado no repositório"

# Verificar se os pacotes foram baixados
if [ ! -f tailscale-core.ipk ]; then
    echo "=========================================="
    echo "ERRO: Pacote IPK não encontrado no repositório"
    echo "=========================================="
    echo "Por favor, transfira os pacotes manualmente:"
    echo "1. Baixe: https://github.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/releases"
    echo "2. Transfira para o roteador:"
    echo "   scp tailscale-zlan9809m-core_*.ipk root@router-ip:/tmp/"
    echo "   scp luci-app-tailscale-zlan9809m_*.ipk root@router-ip:/tmp/"
    echo "3. Execute: ./cleanup.sh && ./install.sh"
    exit 1
fi

# Executar limpeza
echo "=========================================="
echo "Executando limpeza de espaço..."
echo "=========================================="
./cleanup.sh

# Instalar dependências
echo "=========================================="
echo "Instalando dependências..."
echo "=========================================="
opkg update
opkg install kmod-tun ca-bundle xz

# Instalar pacote core
echo "=========================================="
echo "Instalando Tailscale Core..."
echo "=========================================="
opkg install tailscale-core.ipk

# Instalar pacote LuCI
if [ -f tailscale-luci.ipk ]; then
    echo "=========================================="
    echo "Instalando LuCI..."
    echo "=========================================="
    opkg install tailscale-luci.ipk
    /etc/init.d/uhttpd restart
fi

# Configurar Tailscale
echo "=========================================="
echo "Configurando Tailscale..."
echo "=========================================="
echo "NOTA: Você precisa configurar sua auth key do Tailscale"
echo "Obtenha em: https://tailscale.com/settings/keys"
echo ""
read -p "Digite sua auth key (tskey-auth-xxx) ou pressione ENTER para configurar depois: " AUTH_KEY

if [ -n "$AUTH_KEY" ]; then
    uci set tailscale.@tailscale[0].enabled='1'
    uci set tailscale.@tailscale[0].auth_key="$AUTH_KEY"
    uci set tailscale.@tailscale[0].advertise_routes='192.168.1.0/24'
    uci set tailscale.@tailscale[0].accept_routes='1'
    uci set tailscale.@tailscale[0].accept_dns='1'
    uci commit tailscale
    
    # Iniciar serviço
    /etc/init.d/tailscale start
    /etc/init.d/tailscale enable
    
    echo "Tailscale iniciado e configurado!"
else
    echo "Configuração pulada. Configure manualmente:"
    echo "  uci set tailscale.@tailscale[0].enabled='1'"
    echo "  uci set tailscale.@tailscale[0].auth_key='tskey-auth-SEU-KEY'"
    echo "  uci set tailscale.@tailscale[0].advertise_routes='192.168.1.0/24'"
    echo "  uci commit tailscale"
    echo "  /etc/init.d/tailscale start"
    echo "  /etc/init.d/tailscale enable"
fi

# Mostrar estado DEPOIS
echo ""
echo "=========================================="
echo "Estado DEPOIS das Modificações"
echo "=========================================="
echo "Espaço em /overlay (flash):"
df -h /overlay
echo ""
echo "Uso de RAM:"
free -h
echo ""
echo "Pacotes instalados: $(opkg list-installed | wc -l)"
echo ""

# Limpar diretório temporário
cd /
rm -rf "$TMPDIR"

# Resumo final
echo "=========================================="
echo "Instalação Concluída!"
echo "=========================================="
echo ""
echo "Resumo das modificações:"
echo "- Pacotes desnecessários removidos (WireGuard, OpenVPN, etc.)"
echo "- Tailscale instalado e configurado"
echo "- LuCI instalada (interface web)"
echo "- WiFi e 4G/LTE preservados"
echo "- Bluetooth removido (economia de espaço)"
echo ""
echo "Acesse LuCI:"
echo "  http://$(uci get network.lan.ipaddr)/cgi-bin/luci/admin/network/tailscale"
echo ""
echo "Verifique o status do Tailscale:"
echo "  tailscale status"
echo ""
echo "Para monitorar CPU:"
echo "  curl -L $REPO_URL/cpu_monitor.sh -o /tmp/cpu_monitor.sh"
echo "  chmod +x /tmp/cpu_monitor.sh"
echo "  /tmp/cpu_monitor.sh"
echo ""
echo "=========================================="
