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

# Criar diretório temporário
TMPDIR="/tmp/tailscale_auto_install"
mkdir -p "$TMPDIR"
cd "$TMPDIR"

# Detectar curl ou wget
if command -v curl >/dev/null 2>&1; then
    DOWNLOAD_TOOL="curl"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD_TOOL="wget"
else
    echo "ERRO: curl ou wget não encontrado. Instale um deles primeiro."
    exit 1
fi

REPO_URL="https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main"

download_file() {
    local source_url="$1"
    local output_file="$2"
    local description="$3"
    local partial_file="${output_file}.part"

    rm -f "$output_file" "$partial_file"
    echo "Baixando $description..."

    if [ "$DOWNLOAD_TOOL" = "curl" ]; then
        if ! curl -fL --retry 3 --retry-delay 2 -o "$partial_file" "$source_url"; then
            rm -f "$partial_file"
            echo "ERRO: Falha ao baixar $description." >&2
            return 1
        fi
    elif ! wget -q -O "$partial_file" "$source_url"; then
        rm -f "$partial_file"
        echo "ERRO: Falha ao baixar $description." >&2
        return 1
    fi

    if [ ! -s "$partial_file" ]; then
        rm -f "$partial_file"
        echo "ERRO: O download de $description está vazio." >&2
        return 1
    fi

    mv "$partial_file" "$output_file"
}

install_opkg_package() {
    local package_name="$1"

    echo "Instalando dependência: $package_name"
    opkg install "$package_name"
}

install_remote_ipk() {
    local description="$1"
    local repository_path="$2"
    local local_file="$3"

    echo "=========================================="
    echo "Baixando e instalando $description..."
    echo "=========================================="

    if ! download_file "$REPO_URL/$repository_path" "$local_file" "$description"; then
        return 1
    fi

    if ! opkg install "./$local_file"; then
        rm -f "$local_file"
        echo "ERRO: Falha ao instalar $description." >&2
        return 1
    fi

    rm -f "$local_file"
    echo "$description instalado; arquivo temporário removido."
}

install_remote_file() {
    local description="$1"
    local repository_path="$2"
    local destination="$3"
    local permissions="$4"
    local temporary_file="remote-component.tmp"

    if ! download_file "$REPO_URL/$repository_path" "$temporary_file" "$description"; then
        return 1
    fi

    if ! cp "$temporary_file" "$destination"; then
        rm -f "$temporary_file"
        echo "ERRO: Falha ao copiar $description para $destination." >&2
        return 1
    fi

    chmod "$permissions" "$destination"
    rm -f "$temporary_file"
    echo "$description instalado; arquivo temporário removido."
}

# Corrigir feeds duplicados e garantir que o OPKG consiga criar seu lock.
echo "=========================================="
echo "Preparando OPKG..."
echo "=========================================="
if ! download_file "$REPO_URL/opkg-preflight.sh" opkg-preflight.sh "preparador do OPKG"; then
    echo "ERRO: Não foi possível baixar o preparador do OPKG." >&2
    exit 1
fi
chmod +x opkg-preflight.sh
./opkg-preflight.sh
rm -f opkg-preflight.sh
echo "Pacotes instalados: $(opkg list-installed | wc -l)"
echo ""

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
install_opkg_package kmod-tun
install_opkg_package ca-bundle
install_opkg_package xz

# Baixar e instalar cada IPK separadamente para limitar o uso de /tmp.
install_remote_ipk \
    "Tailscale Core" \
    "output/tailscale-zlan9809m-core_1.68.1-1_mipsel_24kc.ipk" \
    "tailscale-core.ipk"

# Instalar pacote LuCI
if install_remote_ipk \
    "Tailscale LuCI" \
    "output/luci-app-tailscale-zlan9809m_1.68.1-1_mipsel_24kc.ipk" \
    "tailscale-luci.ipk"; then
    /etc/init.d/uhttpd restart
else
    echo "AVISO: Tailscale Core foi instalado, mas a interface LuCI falhou." >&2
fi

# Instalar Modbus+MQTT se solicitado
if [ "$INSTALL_MODBUS_MQTT" = "y" ]; then
    echo "=========================================="
    echo "Instalando Modbus+MQTT..."
    echo "=========================================="
    install_remote_ipk \
        "libmodbus" \
        "output/libmodbus_3.1.10-1_mipsel_24kc.ipk" \
        "libmodbus.ipk"
    install_remote_ipk \
        "Mosquitto Client" \
        "output/mosquitto-client_2.0.18-1_mipsel_24kc.ipk" \
        "mosquitto-client.ipk"
    install_remote_ipk \
        "Modbus Daemon" \
        "output/modbus-daemon_1.0-1_mipsel_24kc.ipk" \
        "modbus-daemon.ipk"
    install_remote_ipk \
        "MQTT Daemon" \
        "output/mqtt-daemon_1.0-1_mipsel_24kc.ipk" \
        "mqtt-daemon.ipk"
    install_remote_ipk \
        "LuCI Modbus" \
        "output/luci-app-modbus_1.0-1_mipsel_24kc.ipk" \
        "luci-modbus.ipk"
    install_remote_ipk \
        "LuCI MQTT" \
        "output/luci-app-mqtt_1.0-1_mipsel_24kc.ipk" \
        "luci-mqtt.ipk"

    /etc/init.d/uhttpd restart
    
    echo "Modbus+MQTT instalado!"
fi

# Instalar Terminal Web se solicitado
if [ "$INSTALL_TERMINAL" = "y" ]; then
    echo "=========================================="
    echo "Instalando Terminal Web..."
    echo "=========================================="
    install_opkg_package luci-app-terminal
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

    install_remote_file \
        "Auto-Update Daemon" \
        "scripts/auto-update-daemon.sh" \
        "/usr/lib/auto-update/auto-update-daemon.sh" \
        "0755"
    install_remote_file \
        "whitelist do Auto-Update" \
        "scripts/auto-update-whitelist.conf" \
        "/etc/auto-update-whitelist.conf" \
        "0644"
    
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
    
    # Criar diretório para módulo LuCI
    mkdir -p /usr/lib/lua/luci/controller
    mkdir -p /usr/lib/lua/luci/model/cbi
    mkdir -p /usr/lib/lua/luci/view/cpufreq

    install_remote_file \
        "CPU Governor Manager" \
        "cpu-governor-manager.sh" \
        "/usr/bin/cpu-governor-manager.sh" \
        "0755"
    install_remote_file \
        "serviço CPU Frequency Manager" \
        "files/etc/init.d/cpufreq-manager" \
        "/etc/init.d/cpufreq-manager" \
        "0755"
    install_remote_file \
        "controller LuCI de CPU" \
        "luci/cpufreq/luasrc/controller/cpufreq.lua" \
        "/usr/lib/lua/luci/controller/cpufreq.lua" \
        "0644"
    install_remote_file \
        "modelo LuCI de CPU" \
        "luci/cpufreq/luasrc/model/cbi/cpufreq.lua" \
        "/usr/lib/lua/luci/model/cbi/cpufreq.lua" \
        "0644"

    for view_name in frequency governor max_frequency temperature; do
        install_remote_file \
            "view LuCI de CPU: $view_name" \
            "luci/cpufreq/luasrc/view/cpufreq/$view_name.htm" \
            "/usr/lib/lua/luci/view/cpufreq/$view_name.htm" \
            "0644"
    done
    
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
