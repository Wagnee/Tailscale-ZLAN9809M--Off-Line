#!/bin/bash
# Script de recuperação - Reinstala pacotes removidos pelo cleanup.sh
# Execute este script se precisar restaurar funcionalidades

set -e

echo "=========================================="
echo "Script de Recuperação - Tailscale Cleanup"
echo "=========================================="
echo ""

RECOVERY_FILE="/etc/tailscale_cleanup_removed.txt"

if [ ! -f "$RECOVERY_FILE" ]; then
    echo "ERRO: Arquivo de recuperação não encontrado: $RECOVERY_FILE"
    echo "Este script deve ser executado após o cleanup.sh"
    exit 1
fi

echo "Pacotes a reinstalar:"
cat "$RECOVERY_FILE"
echo ""

echo "=========================================="
echo "Atualizando lista de pacotes..."
echo "=========================================="
opkg update

echo "=========================================="
echo "Reinstalando pacotes removidos..."
echo "=========================================="

while read -r package; do
    if [ -n "$package" ]; then
        echo "Instalando $package..."
        opkg install "$package" || echo "AVISO: Falha ao instalar $package"
    fi
done < "$RECOVERY_FILE"

echo ""
echo "=========================================="
echo "Recuperação concluída!"
echo "=========================================="
echo ""
echo "Pacotes reinstalados com sucesso."
echo "Reinicie o roteador se necessário:"
echo "  reboot"
echo ""
echo "=========================================="

# Remover arquivo de recuperação após sucesso
read -p "Remover arquivo de recuperação? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f "$RECOVERY_FILE"
    echo "Arquivo de recuperação removido."
fi

echo "=========================================="
