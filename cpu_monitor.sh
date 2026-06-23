#!/bin/bash
# Script de monitoramento de CPU e Clock do ZLAN9809M
# Monitora uso de CPU, temperatura e frequência do processador

set -e

echo "=========================================="
echo "Monitoramento de CPU - ZLAN9809M"
echo "=========================================="
echo ""

# Função para mostrar uso de CPU
show_cpu_usage() {
    echo "=========================================="
    echo "Uso de CPU"
    echo "=========================================="
    top -bn1 | grep "Cpu(s)" || echo "Não foi possível obter uso de CPU"
    echo ""
}

# Função para mostrar carga do sistema
show_load() {
    echo "=========================================="
    echo "Carga do Sistema"
    echo "=========================================="
    cat /proc/loadavg
    echo ""
}

# Função para mostrar frequência do processador
show_cpu_freq() {
    echo "=========================================="
    echo "Frequência do Processador"
    echo "=========================================="
    if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
        echo "Frequência atual: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) kHz"
        echo "Frequência máxima: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq) kHz"
        echo "Frequência mínima: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq) kHz"
        echo "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
    else
        echo "Informações de frequência não disponíveis (pode ser fixa)"
    fi
    echo ""
}

# Função para mostrar temperatura
show_temperature() {
    echo "=========================================="
    echo "Temperatura"
    echo "=========================================="
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
        TEMP_C=$((TEMP / 1000))
        echo "Temperatura: ${TEMP_C}°C"
    else
        echo "Informações de temperatura não disponíveis"
    fi
    echo ""
}

# Função para mostrar uso de memória
show_memory() {
    echo "=========================================="
    echo "Uso de Memória"
    echo "=========================================="
    free -h
    echo ""
}

# Função para mostrar processos top
show_top_processes() {
    echo "=========================================="
    echo "Top 5 Processos por Uso de CPU"
    echo "=========================================="
    ps aux --sort=-%cpu | head -6
    echo ""
}

# Função para mostrar especificações do processador
show_cpu_info() {
    echo "=========================================="
    echo "Especificações do Processador"
    echo "=========================================="
    echo "Modelo: $(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d: -f2 | xargs)"
    echo "Cores: $(nproc)"
    echo "Arquitetura: $(uname -m)"
    echo ""
}

# Função para mostrar uso do Tailscale
show_tailscale_usage() {
    echo "=========================================="
    echo "Uso do Tailscale"
    echo "=========================================="
    if pgrep -x "tailscaled" > /dev/null; then
        echo "Tailscale está rodando"
        echo "PID: $(pgrep -x tailscaled)"
        echo "Uso de CPU:"
        ps aux | grep tailscaled | grep -v grep
        echo "Uso de memória:"
        ps aux | grep tailscaled | grep -v grep | awk '{print $6}'
    else
        echo "Tailscale não está rodando"
    fi
    echo ""
}

# Função de monitoramento contínuo
continuous_monitor() {
    echo "=========================================="
    echo "Monitoramento Contínuo (CTRL+C para parar)"
    echo "=========================================="
    echo ""
    
    while true; do
        clear
        echo "=========================================="
        echo "Monitoramento de CPU - ZLAN9809M"
        echo "Data: $(date)"
        echo "=========================================="
        echo ""
        
        show_cpu_info
        show_cpu_freq
        show_temperature
        show_load
        show_cpu_usage
        show_memory
        show_top_processes
        show_tailscale_usage
        
        echo "=========================================="
        echo "Atualizando em 5 segundos... (CTRL+C para parar)"
        echo "=========================================="
        
        sleep 5
    done
}

# Menu principal
case "${1:-single}" in
    continuous)
        continuous_monitor
        ;;
    single)
        show_cpu_info
        show_cpu_freq
        show_temperature
        show_load
        show_cpu_usage
        show_memory
        show_top_processes
        show_tailscale_usage
        
        echo "=========================================="
        echo "Monitoramento concluído"
        echo "=========================================="
        echo ""
        echo "Para monitoramento contínuo, execute:"
        echo "  $0 continuous"
        echo ""
        echo "=========================================="
        ;;
    *)
        echo "Uso: $0 [single|continuous]"
        echo "  single     - Mostra snapshot atual (padrão)"
        echo "  continuous - Monitoramento contínuo atualizando a cada 5s"
        exit 1
        ;;
esac
