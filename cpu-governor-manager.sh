#!/bin/bash
# cpu-governor-manager.sh - Script para gerenciar CPU governor e temperatura
# Uso: ./cpu-governor-manager.sh [set|get|status] [governor]

CPUFREQ_DIR="/sys/devices/system/cpu/cpu0/cpufreq"
THERMAL_DIR="/sys/class/thermal"
CONFIG_FILE="/etc/config/cpufreq"

# Verificar se CPU frequency scaling está disponível
check_cpufreq() {
    if [ ! -d "$CPUFREQ_DIR" ]; then
        echo "ERRO: CPU frequency scaling não disponível neste sistema"
        echo "Verifique se o kernel suporta cpufreq para MT7628NN"
        exit 1
    fi
}

# Obter temperatura atual
get_temperature() {
    # Tentar diferentes paths de thermal zones
    for zone in $(ls -d $THERMAL_DIR/thermal_zone* 2>/dev/null); do
        if [ -f "$zone/temp" ]; then
            temp=$(cat "$zone/temp")
            if [ -n "$temp" ] && [ "$temp" != "0" ]; then
                # Converter de milicelsius para celsius
                temp_c=$((temp / 1000))
                echo "$temp_c°C"
                return 0
            fi
        fi
    done
    
    # Se não encontrar sensor, tentar outro método
    echo "Sensor não disponível"
    return 1
}

# Obter governador atual
get_governor() {
    if [ -f "$CPUFREQ_DIR/scaling_governor" ]; then
        cat "$CPUFREQ_DIR/scaling_governor"
    else
        echo "Não disponível"
    fi
}

# Obter governadores disponíveis
get_available_governors() {
    if [ -f "$CPUFREQ_DIR/scaling_available_governors" ]; then
        cat "$CPUFREQ_DIR/scaling_available_governors"
    else
        echo "Não disponível"
    fi
}

# Obter frequência atual
get_current_freq() {
    if [ -f "$CPUFREQ_DIR/scaling_cur_freq" ]; then
        freq=$(cat "$CPUFREQ_DIR/scaling_cur_freq")
        echo "$((freq / 1000))MHz"
    else
        echo "Não disponível"
    fi
}

# Obter frequência máxima
get_max_freq() {
    if [ -f "$CPUFREQ_DIR/scaling_max_freq" ]; then
        freq=$(cat "$CPUFREQ_DIR/scaling_max_freq")
        echo "$((freq / 1000))MHz"
    else
        echo "Não disponível"
    fi
}

# Definir governador
set_governor() {
    local governor="$1"
    
    check_cpufreq
    
    # Verificar se governador está disponível
    available=$(get_available_governors)
    if echo "$available" | grep -q "$governor"; then
        echo "$governor" > "$CPUFREQ_DIR/scaling_governor"
        echo "Governador definido para: $governor"
        
        # Salvar configuração
        save_config "$governor"
    else
        echo "ERRO: Governador '$governor' não disponível"
        echo "Governadores disponíveis: $available"
        exit 1
    fi
}

# Salvar configuração
save_config() {
    local governor="$1"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    echo "config cpufreq 'settings'" > "$CONFIG_FILE"
    echo "  option governor '$governor'" >> "$CONFIG_FILE"
}

# Carregar configuração
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        governor=$(uci get cpufreq.settings.governor 2>/dev/null)
        if [ -n "$governor" ]; then
            set_governor "$governor"
        fi
    fi
}

# Mostrar status completo
show_status() {
    check_cpufreq
    
    echo "=========================================="
    echo "CPU Frequency Status"
    echo "=========================================="
    echo ""
    echo "Governador atual: $(get_governor)"
    echo "Governadores disponíveis: $(get_available_governors)"
    echo "Frequência atual: $(get_current_freq)"
    echo "Frequência máxima: $(get_max_freq)"
    echo "Temperatura: $(get_temperature)"
    echo ""
    echo "=========================================="
}

# Main
case "${1:-help}" in
    set)
        if [ -z "$2" ]; then
            echo "Uso: $0 set [governor]"
            echo "Governores comuns: performance, ondemand, conservative, powersave"
            exit 1
        fi
        set_governor "$2"
        ;;
    get)
        get_governor
        ;;
    temp)
        get_temperature
        ;;
    status)
        show_status
        ;;
    load)
        load_config
        ;;
    help|*)
        echo "Uso: $0 [set|get|temp|status|load] [governor]"
        echo ""
        echo "Comandos:"
        echo "  set [governor]  - Define o governador da CPU"
        echo "  get              - Mostra o governador atual"
        echo "  temp             - Mostra a temperatura atual"
        echo "  status           - Mostra status completo"
        echo "  load             - Carrega configuração salva"
        echo ""
        echo "Governores:"
        echo "  performance  - Frequência máxima sempre"
        echo "  ondemand     - Ajusta dinamicamente conforme carga"
        echo "  conservative - Similar a ondemand, mais conservador"
        echo "  powersave    - Frequência mínima sempre"
        echo ""
        echo "Recomendações:"
        echo "  Rack de automação (quente): conservative ou powersave"
        echo "  Ambiente ventilado: ondemand"
        echo "  Performance máxima: performance"
        exit 1
        ;;
esac
