#!/bin/bash
# auto-update-daemon.sh - Daemon de auto-update com whitelist
# Verifica scripts no repositório a cada intervalo configurado
# Só executa scripts que estão na whitelist

# Configurações
REPO_URL="https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main/scripts"
WHITELIST_FILE="/etc/auto-update-whitelist.conf"
CHECK_INTERVAL=600  # 10 minutos (configurável)
EXECUTED_SCRIPTS_DIR="/var/lib/auto-update-executed"
LOG_FILE="/var/log/auto-update-daemon.log"

# Criar diretórios necessários
mkdir -p "$EXECUTED_SCRIPTS_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Função de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Função para verificar se script está na whitelist
check_whitelist() {
    local script_name="$1"
    
    if [ ! -f "$WHITELIST_FILE" ]; then
        log "ERRO: Arquivo de whitelist não encontrado: $WHITELIST_FILE"
        return 1
    fi
    
    if grep -q "^${script_name}:" "$WHITELIST_FILE"; then
        log "Script $script_name está na whitelist."
        return 0
    else
        log "Script $script_name NÃO está na whitelist. Execução recusada."
        return 1
    fi
}

# Função para baixar script
download_script() {
    local script_name="$1"
    local script_url="$REPO_URL/$script_name"
    
    if curl -s "$script_url" -o "/tmp/$script_name"; then
        return 0
    else
        log "ERRO: Falha ao baixar $script_name"
        return 1
    fi
}

# Função para executar script
execute_script() {
    local script_name="$1"
    
    log "Executando script: $script_name"
    chmod +x "/tmp/$script_name"
    
    # Executar em subshell com timeout de 5 minutos
    timeout 300 /tmp/$script_name 2>&1 | tee -a "$LOG_FILE"
    local exit_code=${PIPESTATUS[0]}
    
    if [ $exit_code -eq 0 ]; then
        log "Script $script_name executado com sucesso."
        return 0
    else
        log "ERRO: Script $script_name falhou com código $exit_code."
        return 1
    fi
}

# Loop principal
log "Iniciando daemon de auto-update..."
log "Repositório: $REPO_URL"
log "Whitelist: $WHITELIST_FILE"
log "Intervalo de verificação: $CHECK_INTERVAL segundos"

while true; do
    log "Verificando scripts no repositório..."
    
    # Baixar lista de scripts
    SCRIPTS=$(curl -s "$REPO_URL/" | grep -oP 'href="\K[^"]+\.sh(?=")')
    
    if [ -z "$SCRIPTS" ]; then
        log "Nenhum script encontrado no repositório."
    else
        log "Scripts encontrados: $SCRIPTS"
        
        for script in $SCRIPTS; do
            # Pular o próprio daemon e o arquivo de whitelist
            if [ "$script" = "auto-update-daemon.sh" ] || [ "$script" = "auto-update-whitelist.conf" ]; then
                log "Pulando $script (arquivo de sistema)"
                continue
            fi
            
            # Verificar whitelist
            if ! check_whitelist "$script"; then
                continue
            fi
            
            # Baixar script
            if ! download_script "$script"; then
                continue
            fi
            
            # Calcular hash do script
            HASH=$(md5sum "/tmp/$script" | awk '{print $1}')
            
            # Verificar se já foi executado
            if [ -f "$EXECUTED_SCRIPTS_DIR/$script.hash" ] && [ "$(cat $EXECUTED_SCRIPTS_DIR/$script.hash)" = "$HASH" ]; then
                log "Script $script já executado (hash igual). Pulando."
                rm "/tmp/$script"
                continue
            fi
            
            # Executar script
            if execute_script "$script"; then
                # Salvar hash para evitar execução duplicada
                echo "$HASH" > "$EXECUTED_SCRIPTS_DIR/$script.hash"
            fi
            
            # Limpar script temporário
            rm "/tmp/$script"
        done
    fi
    
    log "Aguardando $CHECK_INTERVAL segundos para próxima verificação..."
    sleep $CHECK_INTERVAL
done
