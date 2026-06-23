#!/bin/bash
# cleanup.sh - Script para limpar espaço no ZLAN9809M
# Remove pacotes não utilizados para liberar espaço para Tailscale

set -e

echo "=========================================="
echo "Limpeza de Espaço - ZLAN9809M"
echo "=========================================="
echo ""

# Backup da lista atual
echo "Fazendo backup da lista de pacotes..."
opkg list-installed > /tmp/packages_before.txt

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

# Limpar cache opkg
echo "=========================================="
echo "Limpando cache opkg..."
echo "=========================================="
opkg clean

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
