#!/bin/bash
# system-benchmark.sh - Script de benchmark para ZLAN9809M
# Coleta dados do sistema antes e depois da instalação
# Uso: ./system-benchmark.sh [before|after|compare]

set -e

BENCHMARK_DIR="/tmp/system-benchmark"
BEFORE_FILE="$BENCHMARK_DIR/before.txt"
AFTER_FILE="$BENCHMARK_DIR/after.txt"
REPORT_FILE="$BENCHMARK_DIR/report.txt"

# Criar diretório
mkdir -p "$BENCHMARK_DIR"

# Função para coletar dados do sistema
collect_data() {
    local output_file="$1"
    
    echo "==========================================" | tee -a "$output_file"
    echo "SYSTEM BENCHMARK - $(date)" | tee -a "$output_file"
    echo "==========================================" | tee -a "$output_file"
    echo ""
    
    # Informações do sistema
    echo "=== SYSTEM INFO ===" | tee -a "$output_file"
    echo "Hostname: $(hostname)" | tee -a "$output_file"
    echo "Uptime: $(uptime)" | tee -a "$output_file"
    echo "Kernel: $(uname -r)" | tee -a "$output_file"
    echo "Architecture: $(uname -m)" | tee -a "$output_file"
    echo "OpenWrt Version: $(cat /etc/openwrt_release | grep DISTRIB_DESCRIPTION | cut -d'"' -f2)" | tee -a "$output_file"
    echo ""
    
    # Informações de hardware
    echo "=== HARDWARE INFO ===" | tee -a "$output_file"
    echo "CPU Cores: $(nproc)" | tee -a "$output_file"
    echo "CPU Model: $(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d':' -f2 | xargs)" | tee -a "$output_file"
    echo "CPU MHz: $(cat /proc/cpuinfo | grep 'cpu MHz' | head -1 | cut -d':' -f2 | xargs)" | tee -a "$output_file"
    echo ""
    
    # Uso de RAM
    echo "=== MEMORY USAGE ===" | tee -a "$output_file"
    free -h | tee -a "$output_file"
    echo ""
    echo "RAM Detalhado (MB):" | tee -a "$output_file"
    free -m | tee -a "$output_file"
    echo ""
    
    # Uso de disco
    echo "=== STORAGE USAGE ===" | tee -a "$output_file"
    df -h | tee -a "$output_file"
    echo ""
    echo "Overlay Detalhado:" | tee -a "$output_file"
    df -h /overlay | tee -a "$output_file"
    echo ""
    
    # Pacotes instalados
    echo "=== PACKAGES ===" | tee -a "$output_file"
    echo "Total de pacotes instalados: $(opkg list-installed | wc -l)" | tee -a "$output_file"
    echo ""
    echo "Pacotes principais:" | tee -a "$output_file"
    opkg list-installed | grep -E "(tailscale|modbus|mqtt|mosquitto|luci)" | tee -a "$output_file" || echo "Nenhum pacote principal encontrado" | tee -a "$output_file"
    echo ""
    
    # Processos rodando
    echo "=== PROCESSES ===" | tee -a "$output_file"
    echo "Total de processos: $(ps | wc -l)" | tee -a "$output_file"
    echo ""
    echo "Top 10 processos por memória:" | tee -a "$output_file"
    ps | sort -k4 -nr | head -10 | tee -a "$output_file"
    echo ""
    
    # Serviços rodando
    echo "=== SERVICES ===" | tee -a "$output_file"
    echo "Serviços habilitados:" | tee -a "$output_file"
    /etc/init.d/* enabled 2>/dev/null | while read service; do
        echo "  $service" | tee -a "$output_file"
    done
    echo ""
    
    # Network
    echo "=== NETWORK ===" | tee -a "$output_file"
    echo "Interfaces:" | tee -a "$output_file"
    ip addr show | tee -a "$output_file"
    echo ""
    echo "Rotas:" | tee -a "$output_file"
    ip route show | tee -a "$output_file"
    echo ""
    
    # Tailscale status (se instalado)
    if command -v tailscale >/dev/null 2>&1; then
        echo "=== TAILSCALE STATUS ===" | tee -a "$output_file"
        tailscale status 2>/dev/null | tee -a "$output_file" || echo "Tailscale não configurado" | tee -a "$output_file"
        echo ""
    fi
    
    # Modbus/MQTT daemons (se instalados)
    if pgrep modbus-daemon >/dev/null; then
        echo "=== MODBUS DAEMON ===" | tee -a "$output_file"
        echo "Status: Rodando" | tee -a "$output_file"
        ps | grep modbus-daemon | tee -a "$output_file"
        echo ""
    fi
    
    if pgrep mqtt-daemon >/dev/null; then
        echo "=== MQTT DAEMON ===" | tee -a "$output_file"
        echo "Status: Rodando" | tee -a "$output_file"
        ps | grep mqtt-daemon | tee -a "$output_file"
        echo ""
    fi
    
    echo "==========================================" | tee -a "$output_file"
    echo "BENCHMARK COMPLETED" | tee -a "$output_file"
    echo "==========================================" | tee -a "$output_file"
}

# Função para comparar antes e depois
compare_data() {
    if [ ! -f "$BEFORE_FILE" ]; then
        echo "ERRO: Arquivo 'before.txt' não encontrado. Execute primeiro: ./system-benchmark.sh before"
        exit 1
    fi
    
    if [ ! -f "$AFTER_FILE" ]; then
        echo "ERRO: Arquivo 'after.txt' não encontrado. Execute primeiro: ./system-benchmark.sh after"
        exit 1
    fi
    
    echo "==========================================" > "$REPORT_FILE"
    echo "SYSTEM BENCHMARK COMPARISON REPORT" >> "$REPORT_FILE"
    echo "==========================================" >> "$REPORT_FILE"
    echo ""
    
    # Extrair dados específicos para comparação
    BEFORE_RAM=$(grep "Mem:" "$BEFORE_FILE" | awk '{print $2}')
    AFTER_RAM=$(grep "Mem:" "$AFTER_FILE" | awk '{print $2}')
    
    BEFORE_PACKAGES=$(grep "Total de pacotes instalados:" "$BEFORE_FILE" | awk '{print $5}')
    AFTER_PACKAGES=$(grep "Total de pacotes instalados:" "$AFTER_FILE" | awk '{print $5}')
    
    BEFORE_OVERLAY=$(grep "/overlay" "$BEFORE_FILE" | awk '{print $5}' | tr -d '%')
    AFTER_OVERLAY=$(grep "/overlay" "$AFTER_FILE" | awk '{print $5}' | tr -d '%')
    
    BEFORE_PROCESSES=$(grep "Total de processos:" "$BEFORE_FILE" | awk '{print $4}')
    AFTER_PROCESSES=$(grep "Total de processos:" "$AFTER_FILE" | awk '{print $4}')
    
    echo "=== SUMMARY ===" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "RAM Usage:" >> "$REPORT_FILE"
    echo "  Before: $BEFORE_RAM" >> "$REPORT_FILE"
    echo "  After:  $AFTER_RAM" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "Storage (/overlay):" >> "$REPORT_FILE"
    echo "  Before: $BEFORE_OVERLAY%" >> "$REPORT_FILE"
    echo "  After:  $AFTER_OVERLAY%" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "Packages Installed:" >> "$REPORT_FILE"
    echo "  Before: $BEFORE_PACKAGES" >> "$REPORT_FILE"
    echo "  After:  $AFTER_PACKAGES" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "Processes:" >> "$REPORT_FILE"
    echo "  Before: $BEFORE_PROCESSES" >> "$REPORT_FILE"
    echo "  After:  $AFTER_PROCESSES" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Cálculos de diferença
    echo "=== DIFFERENCES ===" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # RAM
    if [ -n "$BEFORE_RAM" ] && [ -n "$AFTER_RAM" ]; then
        BEFORE_RAM_NUM=$(echo "$BEFORE_RAM" | sed 's/M//')
        AFTER_RAM_NUM=$(echo "$AFTER_RAM" | sed 's/M//')
        RAM_DIFF=$(echo "$AFTER_RAM_NUM - $BEFORE_RAM_NUM" | bc)
        echo "RAM Difference: ${RAM_DIFF}M" >> "$REPORT_FILE"
    fi
    
    # Storage
    if [ -n "$BEFORE_OVERLAY" ] && [ -n "$AFTER_OVERLAY" ]; then
        OVERLAY_DIFF=$(echo "$AFTER_OVERLAY - $BEFORE_OVERLAY" | bc)
        echo "Storage Difference: ${OVERLAY_DIFF}%" >> "$REPORT_FILE"
    fi
    
    # Packages
    if [ -n "$BEFORE_PACKAGES" ] && [ -n "$AFTER_PACKAGES" ]; then
        PACKAGES_DIFF=$(echo "$AFTER_PACKAGES - $BEFORE_PACKAGES" | bc)
        echo "Packages Difference: $PACKAGES_DIFF" >> "$REPORT_FILE"
    fi
    
    # Processes
    if [ -n "$BEFORE_PROCESSES" ] && [ -n "$AFTER_PROCESSES" ]; then
        PROCESSES_DIFF=$(echo "$AFTER_PROCESSES - $BEFORE_PROCESSES" | bc)
        echo "Processes Difference: $PROCESSES_DIFF" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    echo "==========================================" >> "$REPORT_FILE"
    echo "FULL REPORTS:" >> "$REPORT_FILE"
    echo "==========================================" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "Before:" >> "$REPORT_FILE"
    cat "$BEFORE_FILE" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "After:" >> "$REPORT_FILE"
    cat "$AFTER_FILE" >> "$REPORT_FILE"
    
    echo ""
    echo "=========================================="
    echo "RELATÓRIO GERADO: $REPORT_FILE"
    echo "=========================================="
    cat "$REPORT_FILE"
}

# Main
case "${1:-help}" in
    before)
        echo "Coletando dados ANTES da instalação..."
        collect_data "$BEFORE_FILE"
        echo "Dados salvos em: $BEFORE_FILE"
        ;;
    after)
        echo "Coletando dados DEPOIS da instalação..."
        collect_data "$AFTER_FILE"
        echo "Dados salvos em: $AFTER_FILE"
        ;;
    compare)
        echo "Comparando dados antes e depois..."
        compare_data
        ;;
    *)
        echo "Uso: $0 [before|after|compare]"
        echo ""
        echo "Comandos:"
        echo "  before  - Coleta dados antes da instalação"
        echo "  after   - Coleta dados depois da instalação"
        echo "  compare - Gera relatório comparativo"
        echo ""
        echo "Fluxo recomendado:"
        echo "  1. $0 before"
        echo "  2. Execute a instalação"
        echo "  3. $0 after"
        echo "  4. $0 compare"
        exit 1
        ;;
esac
