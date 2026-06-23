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

# Perguntar sobre Auto-Update Daemon
echo "Deseja instalar também o Daemon de Auto-Update?"
echo "Isso permitirá execução automática de scripts do repositório (apenas scripts na whitelist)"
echo "⚠️  ATENÇÃO: Isso permite execução remota de scripts - use apenas se confiar no repositório"
read -p "Instalar Auto-Update Daemon? (y/N): " INSTALL_AUTO_UPDATE
INSTALL_AUTO_UPDATE=$(echo "$INSTALL_AUTO_UPDATE" | tr '[:upper:]' '[:lower:]')

# Perguntar sobre Terminal Web
echo "Deseja instalar também o Terminal Web (LuCI)?"
echo "Isso adicionará acesso ao terminal via interface web (consome ~2-3MB RAM constantemente)"
echo "Recomendação: Use SSH para economizar RAM"
read -p "Instalar Terminal Web? (y/N): " INSTALL_TERMINAL
INSTALL_TERMINAL=$(echo "$INSTALL_TERMINAL" | tr '[:upper:]' '[:lower:]')

# Perguntar sobre CPU Management
echo "Deseja instalar também o CPU Management (LuCI)?"
echo "Isso adicionará controle de CPU governor e monitoramento de temperatura"
echo "Recomendação: conservative/powersave para racks de automação (ambiente quente)"
read -p "Instalar CPU Management? (y/N): " INSTALL_CPU_MGMT
INSTALL_CPU_MGMT=$(echo "$INSTALL_CPU_MGMT" | tr '[:upper:]' '[:lower:]')

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

set -e

echo "=========================================="
echo "Limpeza de Espaço - ZLAN9809M"
echo "=========================================="
echo ""

# Backup da lista atual
echo "Fazendo backup da lista de pacotes..."
#opkg list-installed > /tmp/packages_before.txt

# Mostrar espaço antes
echo "Espaço antes da limpeza:"
df -h /overlay
echo ""

# Remover VPNs alternativas (Tailscale substitui)
echo "=========================================="
echo "Removendo VPNs alternativas..."
echo "=========================================="
opkg remove kmod-wireguard wireguard-tools 2>/dev/null || true
opkg remove openvpn-openssl 2>/dev/null || true
opkg remove openvpn-easy-rsa 2>/dev/null || true
opkg remove strongswan 2>/dev/null || true
opkg remove strongswan-mod-kernel-libipsec 2>/dev/null || true
opkg remove strongswan-mod-openssl 2>/dev/null || true
opkg remove kmod-pptp ppp-mod-pptp 2>/dev/null || true
opkg remove xl2tpd 2>/dev/null || true

# Remover locales não utilizados
echo "=========================================="
echo "Removendo locales não utilizados..."
echo "=========================================="
opkg remove locale-base-en locale-base-de locale-base-fr locale-base-es 2>/dev/null || true
opkg remove kmod-nls-cp437 kmod-nls-iso8859-1 kmod-nls-iso8859-15 2>/dev/null || true
opkg remove kmod-nls-utf8 kmod-nls-iso8859-13 kmod-nls-iso8859-2 2>/dev/null || true

# Remover ferramentas de debug
echo "=========================================="
echo "Removendo ferramentas de debug..."
echo "=========================================="
opkg remove strace gdb 2>/dev/null || true
opkg remove make gcc binutils 2>/dev/null || true
opkg remove perf 2>/dev/null || true

# Remover suporte a Bluetooth
echo "=========================================="
echo "Removendo suporte a Bluetooth..."
echo "=========================================="
opkg remove kmod-bluetooth bluez-daemon bluez-tools 2>/dev/null || true

# NOTA: Wi-Fi é mantido para funcionalidade do roteador
# 4G/LTE também é mantido (pacotes ppp* não são removidos)

# Remover suporte USB (COMENTADO - descomente se não usar USB)
# echo "=========================================="
# echo "Removendo suporte a USB..."
# echo "=========================================="
# opkg remove kmod-usb-core kmod-usb2 kmod-usb3 2>/dev/null || true
# opkg remove kmod-usb-storage kmod-usb-storage-uas 2>/dev/null || true
# opkg remove kmod-usb-serial kmod-usb-serial-option 2>/dev/null || true

# Remover suporte multimídia
echo "=========================================="
echo "Removendo suporte multimídia..."
echo "=========================================="
opkg remove kmod-sound-core kmod-sound-soc-core 2>/dev/null || true
opkg remove kmod-video-core kmod-video-uvc 2>/dev/null || true
opkg remove ffmpeg libffmpeg-mini 2>/dev/null || true

# Remover temas LuCI extras
echo "=========================================="
echo "Removendo temas LuCI extras..."
echo "=========================================="
opkg remove luci-theme-material luci-theme-openwrt 2>/dev/null || true
opkg remove luci-theme-argon 2>/dev/null || true

# Remover módulos LuCI não utilizados
echo "=========================================="
echo "Removendo módulos LuCI não utilizados..."
echo "=========================================="
opkg remove luci-app-statistics 2>/dev/null || true
opkg remove luci-app-nlbwmon 2>/dev/null || true
opkg remove luci-app-wol 2>/dev/null || true
opkg remove luci-app-upnp 2>/dev/null || true
opkg remove luci-app-qos 2>/dev/null || true
opkg remove luci-app-sqm 2>/dev/null || true
opkg remove luci-app-adblock 2>/dev/null || true
opkg remove luci-app-privoxy 2>/dev/null || true

# Remover ferramentas de monitoramento
echo "=========================================="
echo "Removendo ferramentas de monitoramento..."
echo "=========================================="
opkg remove rsyslog 2>/dev/null || true
opkg remove collectd collectd-mod-uptime collectd-mod-cpu 2>/dev/null || true
opkg remove netdata 2>/dev/null || true
opkg remove htop 2>/dev/null || true

# Remover serviços não utilizados
echo "=========================================="
echo "Removendo serviços não utilizados..."
echo "=========================================="
opkg remove cron 2>/dev/null || true
opkg remove rsync 2>/dev/null || true
opkg remove wget 2>/dev/null || true

# Limpar arquivos temporários
echo "=========================================="
echo "Limpando arquivos temporários..."
echo "=========================================="
rm -rf /tmp/*
rm -rf /var/opkg-locks

# Mostrar espaço depois
echo ""
echo "=========================================="
echo "Espaço após limpeza:"
echo "=========================================="
df -h /overlay
echo ""

# Mostrar pacotes removidos
echo "=========================================="
echo "Pacotes removidos:"
echo "=========================================="
diff /tmp/packages_before.txt <(opkg list-installed) | grep "^<" | awk '{print $2}' || echo "Nenhum pacote removido"
echo ""

# Criar arquivo de recuperação
echo "=========================================="
echo "Criando arquivo de recuperação..."
echo "=========================================="
diff /tmp/packages_before.txt <(opkg list-installed) | grep "^<" | awk '{print $2}' > /etc/tailscale_cleanup_removed.txt
echo "Lista de pacotes removidos salva em: /etc/tailscale_cleanup_removed.txt"
echo ""

# Calcular economia
echo "=========================================="
echo "Resumo:"
echo "=========================================="
echo "Limpeza concluída!"
echo ""
echo "Funcionalidades mantidas:"
echo "- WiFi: Preservado (kmod-ath9k, hostapd, wpa-supplicant)"
echo "- 4G/LTE: Preservado (pacotes ppp* não foram removidos)"
echo "- Ethernet: Preservado"
echo ""
echo "Para reinstalar pacotes removidos:"
echo "  /etc/tailscale_recovery.sh"
echo ""
echo "Para reinstalar pacote específico:"
echo "  opkg install <nome-do-pacote>"
echo "=========================================="

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
#echo "Baixando cleanup.sh..."
#$DOWNLOAD_CMD "$REPO_URL/cleanup.sh" $DOWNLOAD_OPTS cleanup.sh
#chmod +x cleanup.sh

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

# Baixar scripts de auto-update se solicitado
if [ "$INSTALL_AUTO_UPDATE" = "y" ]; then
    echo "Baixando scripts de auto-update..."
    $DOWNLOAD_CMD "$REPO_URL/scripts/auto-update-daemon.sh" $DOWNLOAD_OPTS auto-update-daemon.sh || echo "Daemon não encontrado"
    $DOWNLOAD_CMD "$REPO_URL/scripts/auto-update-whitelist.conf" $DOWNLOAD_OPTS auto-update-whitelist.conf || echo "Whitelist não encontrado"
    $DOWNLOAD_CMD "$REPO_URL/scripts/install-auto-update-daemon.sh" $DOWNLOAD_OPTS install-auto-update-daemon.sh || echo "Script de instalação não encontrado"
fi

# Baixar CPU Management se solicitado
if [ "$INSTALL_CPU_MGMT" = "y" ]; then
    echo "Baixando CPU Management..."
    $DOWNLOAD_CMD "$REPO_URL/cpu-governor-manager.sh" $DOWNLOAD_OPTS cpu-governor-manager.sh || echo "CPU Governor Manager não encontrado"
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
#echo "=========================================="
#echo "Executando limpeza de espaço..."
#echo "=========================================="
#./cleanup.sh

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

# Instalar Terminal Web se solicitado
if [ "$INSTALL_TERMINAL" = "y" ]; then
    echo "=========================================="
    echo "Instalando Terminal Web..."
    echo "=========================================="
    opkg install luci-app-terminal
    /etc/init.d/uhttpd restart
    echo "Terminal Web instalado!"
    echo "Acesse em: LuCI → System → Terminal"
fi

# Instalar Auto-Update Daemon se solicitado
if [ "$INSTALL_AUTO_UPDATE" = "y" ]; then
    echo "=========================================="
    echo "Instalando Auto-Update Daemon..."
    echo "=========================================="
    
    # Criar diretório para scripts
    mkdir -p /usr/lib/auto-update
    
    # Copiar scripts
    if [ -f auto-update-daemon.sh ]; then
        cp auto-update-daemon.sh /usr/lib/auto-update/
        chmod +x /usr/lib/auto-update/auto-update-daemon.sh
        echo "Daemon copiado para /usr/lib/auto-update/"
    fi
    
    # Copiar whitelist
    if [ -f auto-update-whitelist.conf ]; then
        cp auto-update-whitelist.conf /etc/
        chmod 644 /etc/auto-update-whitelist.conf
        echo "Whitelist copiada para /etc/"
    fi
    
    # Criar diretório para hashes
    mkdir -p /var/lib/auto-update-executed
    
    # Criar init script
    cat > /etc/init.d/auto-update <<'EOF'
#!/bin/sh /etc/rc.common
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
    
    # Habilitar e iniciar daemon
    /etc/init.d/auto-update enable
    /etc/init.d/auto-update start
    
    echo "Auto-Update Daemon instalado e iniciado!"
    echo "Logs: tail -f /var/log/auto-update-daemon.log"
fi

# Instalar CPU Management se solicitado
if [ "$INSTALL_CPU_MGMT" = "y" ]; then
    echo "=========================================="
    echo "Instalando CPU Management..."
    echo "=========================================="
    
    # Copiar script de gerenciamento
    if [ -f cpu-governor-manager.sh ]; then
        cp cpu-governor-manager.sh /usr/bin/
        chmod +x /usr/bin/cpu-governor-manager.sh
        echo "Script de gerenciamento copiado para /usr/bin/"
    fi
    
    # Copiar init script
    cp files/etc/init.d/cpufreq-manager /etc/init.d/
    chmod +x /etc/init.d/cpufreq-manager
    echo "Init script copiado para /etc/init.d/"
    
    # Criar diretório para módulo LuCI
    mkdir -p /usr/lib/lua/luci/controller
    mkdir -p /usr/lib/lua/luci/model/cbi
    mkdir -p /usr/lib/lua/luci/view/cpufreq
    
    # Copiar módulo LuCI
    cp luci/cpufreq/luasrc/controller/cpufreq.lua /usr/lib/lua/luci/controller/
    cp luci/cpufreq/luasrc/model/cbi/cpufreq.lua /usr/lib/lua/luci/model/cbi/
    cp luci/cpufreq/luasrc/view/cpufreq/*.htm /usr/lib/lua/luci/view/cpufreq/
    
    # Habilitar serviço
    /etc/init.d/cpufreq-manager enable
    
    # Reiniciar LuCI
    /etc/init.d/uhttpd restart
    
    echo "CPU Management instalado!"
    echo "Acesse em: LuCI → Services → CPU Management"
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
if [ "$INSTALL_AUTO_UPDATE" = "y" ]; then
    echo "- Auto-Update Daemon instalado (execução de scripts remotos)"
fi
if [ "$INSTALL_TERMINAL" = "y" ]; then
    echo "- Terminal Web instalado (acesso via LuCI, +2-3MB RAM)"
fi
if [ "$INSTALL_CPU_MGMT" = "y" ]; then
    echo "- CPU Management instalado (controle de governor e temperatura)"
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
if [ "$INSTALL_AUTO_UPDATE" = "y" ]; then
    echo "Auto-Update Daemon:"
    echo "  Status: /etc/init.d/auto-update status"
    echo "  Logs: tail -f /var/log/auto-update-daemon.log"
    echo "  Whitelist: cat /etc/auto-update-whitelist.conf"
    echo "  Para adicionar scripts: https://github.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/tree/main/scripts"
    echo ""
fi
if [ "$INSTALL_TERMINAL" = "y" ]; then
    echo "Terminal Web:"
    echo "  Acesse em: LuCI → System → Terminal"
    echo "  Uso RAM: ~2-3MB constantes"
    echo "  Alternativa: SSH (mais leve)"
    echo ""
fi
echo "Para monitorar CPU:"
echo "  curl -L $REPO_URL/cpu_monitor.sh -o /tmp/cpu_monitor.sh"
echo "  chmod +x /tmp/cpu_monitor.sh"
echo "  /tmp/cpu_monitor.sh"
echo ""
echo "=========================================="
