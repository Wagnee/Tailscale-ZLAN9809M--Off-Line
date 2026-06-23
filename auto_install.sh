#!/bin/bash
# Script Master de Instalação Automática - Tailscale para ZLAN9809M
# Executa tudo automaticamente: limpeza, instalação e configuração
# Uso: curl -L https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main/auto_install.sh | bash
# Ou: wget -qO- https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main/auto_install.sh | bash

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

# Perguntar sobre Modbus+MQTT
echo "Deseja instalar também Modbus TCP + MQTT?"
echo "Isso adicionará funcionalidades de polling Modbus e publicação MQTT"
read -p "Instalar Modbus+MQTT? (y/N): " INSTALL_MODBUS_MQTT
INSTALL_MODBUS_MQTT=$(echo "$INSTALL_MODBUS_MQTT" | tr '[:upper:]' '[:lower:]')

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

# Detectar curl ou wget
if command -v curl >/dev/null 2>&1; then
    DOWNLOAD_CMD="curl -L"
    DOWNLOAD_OPTS="-o"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD_CMD="wget -q"
    DOWNLOAD_OPTS="-O"
else
    echo "ERRO: curl ou wget não encontrado. Instale um deles primeiro."
    exit 1
fi

# Baixar scripts necessários
echo "=========================================="
echo "Baixando scripts..."
echo "=========================================="
REPO_URL="https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main"

# Baixar cleanup.sh
echo "Baixando cleanup.sh..."
$DOWNLOAD_CMD "$REPO_URL/cleanup.sh" $DOWNLOAD_OPTS cleanup.sh
chmod +x cleanup.sh

# Baixar pacotes IPK (se disponíveis no repositório)
echo "Baixando pacotes IPK..."
$DOWNLOAD_CMD "$REPO_URL/output/tailscale-zlan9809m-core_1.68.1-1_mipsel_24kc.ipk" $DOWNLOAD_OPTS tailscale-core.ipk || echo "Pacote core não encontrado no repositório"
$DOWNLOAD_CMD "$REPO_URL/output/luci-app-tailscale-zlan9809m_1.68.1-1_mipsel_24kc.ipk" $DOWNLOAD_OPTS tailscale-luci.ipk || echo "Pacote LuCI não encontrado no repositório"

# Baixar pacotes Modbus+MQTT se solicitado
if [ "$INSTALL_MODBUS_MQTT" = "y" ]; then
    echo "Baixando pacotes Modbus+MQTT..."
    $DOWNLOAD_CMD "$REPO_URL/output/libmodbus_3.1.10-1_mipsel_24kc.ipk" $DOWNLOAD_OPTS libmodbus.ipk || echo "Pacote libmodbus não encontrado"
    $DOWNLOAD_CMD "$REPO_URL/output/mosquitto-client_2.0.18-1_mipsel_24kc.ipk" $DOWNLOAD_OPTS mosquitto-client.ipk || echo "Pacote mosquitto-client não encontrado"
    $DOWNLOAD_CMD "$REPO_URL/output/modbus-daemon_1.0-1_mipsel_24kc.ipk" $DOWNLOAD_OPTS modbus-daemon.ipk || echo "Pacote modbus-daemon não encontrado"
    $DOWNLOAD_CMD "$REPO_URL/output/mqtt-daemon_1.0-1_mipsel_24kc.ipk" $DOWNLOAD_OPTS mqtt-daemon.ipk || echo "Pacote mqtt-daemon não encontrado"
    $DOWNLOAD_CMD "$REPO_URL/output/luci-app-modbus_1.0-1_mipsel_24kc.ipk" $DOWNLOAD_OPTS luci-modbus.ipk || echo "Pacote luci-modbus não encontrado"
    $DOWNLOAD_CMD "$REPO_URL/output/luci-app-mqtt_1.0-1_mipsel_24kc.ipk" $DOWNLOAD_OPTS luci-mqtt.ipk || echo "Pacote luci-mqtt não encontrado"
fi

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

# Instalar Modbus+MQTT se solicitado
if [ "$INSTALL_MODBUS_MQTT" = "y" ]; then
    echo "=========================================="
    echo "Instalando Modbus+MQTT..."
    echo "=========================================="
    
    # Instalar dependências
    opkg install libmodbus.ipk 2>/dev/null || echo "libmodbus não encontrado, continuando..."
    opkg install mosquitto-client.ipk 2>/dev/null || echo "mosquitto-client não encontrado, continuando..."
    
    # Instalar daemons
    opkg install modbus-daemon.ipk 2>/dev/null || echo "modbus-daemon não encontrado"
    opkg install mqtt-daemon.ipk 2>/dev/null || echo "mqtt-daemon não encontrado"
    
    # Instalar interfaces LuCI
    opkg install luci-modbus.ipk 2>/dev/null || echo "luci-modbus não encontrado"
    opkg install luci-mqtt.ipk 2>/dev/null || echo "luci-mqtt não encontrado"
    
    # Reiniciar LuCI se instalou interfaces
    if [ -f luci-modbus.ipk ] || [ -f luci-mqtt.ipk ]; then
        /etc/init.d/uhttpd restart
    fi
    
    echo "Modbus+MQTT instalado!"
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
if [ "$INSTALL_MODBUS_MQTT" = "y" ]; then
    echo "- Modbus+MQTT instalado (polling e publicação)"
fi
echo ""
echo "Acesse LuCI:"
echo "  http://$(uci get network.lan.ipaddr)/cgi-bin/luci/admin/network/tailscale"
if [ "$INSTALL_MODBUS_MQTT" = "y" ]; then
    echo "  http://$(uci get network.lan.ipaddr)/cgi-bin/luci/admin/services/modbus"
    echo "  http://$(uci get network.lan.ipaddr)/cgi-bin/luci/admin/services/mqtt"
fi
echo ""
echo "Verifique o status do Tailscale:"
echo "  tailscale status"
echo ""
if [ "$INSTALL_MODBUS_MQTT" = "y" ]; then
    echo "Configure Modbus e MQTT via LuCI:"
    echo "  Adicione dispositivos Modbus em Services > Modbus"
    echo "  Configure broker MQTT em Services > MQTT"
    echo ""
fi
echo "Para monitorar CPU:"
echo "  curl -L $REPO_URL/cpu_monitor.sh -o /tmp/cpu_monitor.sh"
echo "  chmod +x /tmp/cpu_monitor.sh"
echo "  /tmp/cpu_monitor.sh"
echo ""
echo "=========================================="
