#!/bin/bash
# update.sh - Script de teste para auto-update
# Apenas imprime mensagem de funcionamento

echo "[$(date)] Script update.sh está funcionando!"
echo "[$(date)] Executado em: $(hostname)"
echo "[$(date)] Uptime: $(uptime)"
echo "[$(date)] Memória livre: $(free -m | grep Mem | awk '{print $4}')MB"
echo "[$(date)] Script concluído com sucesso."

exit 0
