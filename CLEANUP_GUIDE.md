# Guia de Limpeza de Espaço - ZLAN9809M

## Visão Geral

Este guia ajuda a liberar espaço no ZLAN9809M removendo pacotes não utilizados. Com Tailscale, muitos pacotes de VPN e recursos extras tornam-se desnecessários.

## Especificações do Equipamento

### Antes das Modificações (Fábrica)
- **Processador**: MediaTek MT7628NN (MIPS 24Kc, 580MHz)
- **RAM**: 64MB/128MB
- **Flash**: 16MB total
- **Espaço Overlay**: ~4MB disponível
- **Funcionalidades**: WiFi, 4G/LTE, Ethernet, Bluetooth
- **Pacotes VPN**: WireGuard, OpenVPN, StrongSwan
- **Temas LuCI**: Múltiplos temas instalados
- **Locales**: Múltiplos idiomas instalados

### Após Modificações (Com Tailscale + Cleanup)
- **Processador**: MediaTek MT7628NN (MIPS 24Kc, 580MHz)
- **RAM**: 64MB/128MB (32MB livres para buffer)
- **Flash**: 16MB total
- **Espaço Overlay**: ~8-12MB disponível (após cleanup)
- **Funcionalidades**: WiFi, 4G/LTE, Ethernet, Tailscale VPN
- **Pacotes VPN**: Tailscale (substitui WireGuard, OpenVPN, StrongSwan)
- **Temas LuCI**: 1 tema (bootstrap)
- **Locales**: pt_BR/en_US apenas
- **Bluetooth**: Removido (economia de espaço)
- **Monitoramento**: Script de CPU/clock incluído

### Benefícios das Modificações
- **Mais espaço**: 8-12MB livres (vs 4MB original)
- **VPN unificada**: Tailscale substitui múltiplas VPNs
- **Sistema mais limpo**: Apenas pacotes necessários
- **Monitoramento**: Controle de uso de CPU incluído
- **Recuperável**: Script de recuperação incluído

## Pacotes VPN Removíveis (Economia Significativa)

### WireGuard e VPNs Alternativas
```bash
# Remover WireGuard (não necessário com Tailscale)
opkg remove kmod-wireguard wireguard-tools

# Remover OpenVPN
opkg remove openvpn-openssl openvpn-easy-rsa

# Remover IPsec/StrongSwan
opkg remove strongswan strongswan-mod-kernel-libipsec strongswan-mod-openssl

# Remover PPTP
opkg remove kmod-pptp ppp-mod-pptp

# Remover L2TP
opkg remove xl2tpd
```

**Economia estimada:** 1-2MB

## Idiomas e Localização

### Remover Locales Não Utilizados
```bash
# Listar locales instalados
opkg list-installed | grep locale

# Remover locales não utilizados (mantendo apenas pt_BR ou en_US)
opkg remove locale-base-en locale-base-de locale-base-fr locale-base-es
opkg remove kmod-nls-cp437 kmod-nls-iso8859-1 kmod-nls-iso8859-15
opkg remove kmod-nls-utf8 kmod-nls-iso8859-13 kmod-nls-iso8859-2
```

**Economia estimada:** 500KB-1MB

## Pacotes de Desenvolvimento e Debug

### Remover Ferramentas de Debug
```bash
# Remover pacotes de debug
opkg remove strace gdb

# Remover ferramentas de desenvolvimento
opkg remove make gcc binutils

# Remover perf e profiling
opkg remove perf
```

**Economia estimada:** 2-3MB

## Pacotes de Rede Não Utilizados

### Remover Protocolos de Rede Extras
```bash
# Remover suporte a IPv6 se não usar
opkg remove kmod-ipv6 ip6tables

# Remover suporte a PPP se não usar modem 3G/4G
opkg remove ppp ppp-mod-pppoe ppp-mod-pppol2tp

# Remover suporte a Bluetooth
opkg remove kmod-bluetooth bluez-daemon bluez-tools

# Remover suporte a Wi-Fi se usar apenas Ethernet
opkg remove kmod-ath9k kmod-ath9k-htc kmod-mac80211 hostapd
opkg remove wpa-supplicant wpad-basic
```

**Economia estimada:** 3-5MB

## Pacotes de Armazenamento e Sistema de Arquivos

### Remover FS Não Utilizados
```bash
# Remover suporte a filesystems não utilizados
opkg remove kmod-fs-ext4 kmod-fs-xfs kmod-fs-btrfs
opkg remove kmod-fs-vfat kmod-fs-ntfs kmod-fs-hfsplus

# Remover suporte a RAID/LVM se não usar
opkg remove kmod-md-mod kmod-md-linear kmod-md-raid0 kmod-md-raid1
opkg remove kmod-md-raid10 kmod-md-raid456 lvm2
```

**Economia estimada:** 1-2MB

## Pacotes Multimídia

### Remover Suporte Multimídia
```bash
# Remover suporte a áudio
opkg remove kmod-sound-core kmod-sound-soc-core

# Remover suporte a vídeo
opkg remove kmod-video-core kmod-video-uvc

# Remover codecs
opkg remove ffmpeg libffmpeg-mini
```

**Economia estimada:** 1-2MB

## Pacotes de Hardware Não Utilizados

### Remover Suporte a Hardware Específico
```bash
# Remover suporte a USB se não usar
opkg remove kmod-usb-core kmod-usb2 kmod-usb3
opkg remove kmod-usb-storage kmod-usb-storage-uas
opkg remove kmod-usb-serial kmod-usb-serial-option

# Remover suporte a SD card
opkg remove kmod-mmc kmod-sdhci

# Remover suporte a GPIO e LEDs extras
opkg remove kmod-gpio-button-hotplug kmod-ledtrig-heartbeat
opkg remove kmod-ledtrig-gpio kmod-ledtrig-netdev
```

**Economia estimada:** 1-2MB

## Pacotes de Sistema

### Remover Serviços Não Utilizados
```bash
# Remover cron se não usar agendamento
opkg remove cron

# Remover rsync se não usar sincronização
opkg remove rsync

# Remover nano/vi se usar apenas SSH
opkg remove nano vim

# Remover wget se usar curl
opkg remove wget

# Remover ca-certificates extras
opkg remove ca-certificates-bundle
```

**Economia estimada:** 500KB-1MB

## Pacotes de Monitoramento e Logs

### Remover Ferramentas de Monitoramento
```bash
# Remover rsyslog se usar logd padrão
opkg remove rsyslog

# Remover collectd se não usar monitoramento
opkg remove collectd collectd-mod-uptime collectd-mod-cpu

# Remover netdata se não usar
opkg remove netdata

# Remover htop se usar top
opkg remove htop
```

**Economia estimada:** 1-2MB

## Pacotes LuCI Não Utilizados

### Remover Módulos LuCI Extras
```bash
# Listar pacotes LuCI instalados
opkg list-installed | grep luci

# Remover temas extras (manter apenas um)
opkg remove luci-theme-bootstrap luci-theme-material
opkg remove luci-theme-openwrt luci-theme-argon

# Remover módulos não utilizados
opkg remove luci-app-firewall luci-app-opkg
opkg remove luci-app-statistics luci-app-nlbwmon
opkg remove luci-app-wol luci-app-upnp
opkg remove luci-app-qos luci-app-sqm
opkg remove luci-app-adblock luci-app-privoxy

# Remover i18n extras
opkg remove luci-i18n-base luci-i18n-firewall
opkg remove luci-i18n-wireless luci-i18n-network
```

**Economia estimada:** 2-5MB

## Script de Limpeza Automática

### Script Completo de Limpeza
```bash
#!/bin/bash
# cleanup.sh - Script para limpar espaço no ZLAN9809M

echo "=========================================="
echo "Limpeza de Espaço - ZLAN9809M"
echo "=========================================="
echo ""

# Backup da lista atual
opkg list-installed > /tmp/packages_before.txt

# Remover VPNs alternativas (Tailscale substitui)
echo "Removendo VPNs alternativas..."
opkg remove kmod-wireguard wireguard-tools 2>/dev/null
opkg remove openvpn-openssl 2>/dev/null
opkg remove strongswan 2>/dev/null

# Remover locales não utilizados
echo "Removendo locales não utilizados..."
opkg remove locale-base-en locale-base-de locale-base-fr 2>/dev/null
opkg remove kmod-nls-cp437 kmod-nls-iso8859-1 2>/dev/null

# Remover ferramentas de debug
echo "Removendo ferramentas de debug..."
opkg remove strace gdb 2>/dev/null

# Remover suporte a IPv6 se não usar
# Descomente se não usar IPv6
# opkg remove kmod-ipv6 ip6tables 2>/dev/null

# Remover suporte a Bluetooth
echo "Removendo suporte a Bluetooth..."
opkg remove kmod-bluetooth bluez-daemon 2>/dev/null

# Remover suporte a Wi-Fi se usar apenas Ethernet
# Descomente se usar apenas Ethernet
# opkg remove kmod-ath9k kmod-mac80211 hostapd 2>/dev/null
# opkg remove wpa-supplicant wpad-basic 2>/dev/null

# Remover suporte USB se não usar
# Descomente se não usar USB
# opkg remove kmod-usb-core kmod-usb-storage 2>/dev/null

# Remover pacotes de desenvolvimento
echo "Removendo pacotes de desenvolvimento..."
opkg remove make gcc binutils 2>/dev/null

# Remover temas LuCI extras
echo "Removendo temas LuCI extras..."
opkg remove luci-theme-material luci-theme-openwrt 2>/dev/null

# Limpar cache opkg
echo "Limpando cache opkg..."
opkg clean

# Limpar arquivos temporários
echo "Limpando arquivos temporários..."
rm -rf /tmp/*
rm -rf /var/opkg-locks

# Mostrar espaço liberado
echo ""
echo "=========================================="
echo "Espaço Antes:"
df -h /overlay
echo ""
echo "Espaço Depois:"
df -h /overlay
echo "=========================================="
echo ""
echo "Lista de pacotes removidos:"
diff /tmp/packages_before.txt <(opkg list-installed) | grep "^<" || echo "Nenhum pacote removido"
echo ""
echo "=========================================="
```

## Como Usar o Script

```bash
# Copiar script para o roteador
scp cleanup.sh root@router-ip:/tmp/

# Executar no roteador
ssh root@router-ip
cd /tmp
chmod +x cleanup.sh
./cleanup.sh
```

## Lista Verificada de Pacotes Seguros para Remover

### Alta Prioridade (Maior economia, menor risco)
- `kmod-wireguard wireguard-tools` - Substituído por Tailscale
- `openvpn-openssl` - Substituído por Tailscale
- `strongswan*` - Substituído por Tailscale
- `kmod-bluetooth bluez-daemon` - Bluetooth não usado em roteador
- `locale-base-*` (exceto pt_BR/en_US) - Idiomas não utilizados
- `luci-theme-*` (exceto um tema) - Temas extras

### Média Prioridade
- `kmod-usb-*` - Se não usar USB
- `kmod-wireless hostapd wpa-supplicant` - Se usar apenas Ethernet
- `kmod-ipv6 ip6tables` - Se não usar IPv6
- `strace gdb make gcc` - Ferramentas de desenvolvimento
- `luci-app-*` - Módulos LuCI não utilizados

### Baixa Prioridade (Verificar antes)
- `ppp*` - Se não usar modem 3G/4G
- `kmod-fs-*` - Se não usar filesystems específicos
- `cron` - Se não usar agendamento
- `rsync` - Se não usar sincronização

## Economia Total Estimada

- **VPN alternativas:** 1-2MB
- **Locales:** 500KB-1MB
- **Desenvolvimento:** 2-3MB
- **Rede extras:** 3-5MB
- **Multimídia:** 1-2MB
- **LuCI extras:** 2-5MB
- **Cache/temp:** 500KB-1MB

**Total possível:** 10-19MB

## Verificação de Espaço

Antes e depois da limpeza:

```bash
# Verificar espaço antes
df -h /overlay

# Verificar espaço depois
df -h /overlay

# Verificar espaço em /tmp (RAM)
df -h /tmp
```

## Recuperação em Caso de Problemas

### Script de Recuperação Automática

O script `cleanup.sh` cria automaticamente um arquivo de recuperação em `/etc/tailscale_cleanup_removed.txt` com a lista de pacotes removidos.

Para recuperar todos os pacotes removidos:

```bash
# Copiar script de recuperação para o roteador
scp tailscale_recovery.sh root@router-ip:/tmp/

# Executar no roteador
ssh root@router-ip
cd /tmp
chmod +x tailscale_recovery.sh
./tailscale_recovery.sh
```

### Recuperação Manual

Se remover algo necessário manualmente:

```bash
# Reinstalar pacote específico
opkg update
opkg install <nome-do-pacote>

# Reinstalar todos os pacotes removidos
for package in $(cat /etc/tailscale_cleanup_removed.txt); do
    opkg install $package
done
```

## Recomendações Específicas para ZLAN9809M

Com Tailscale instalado:

1. **Remova todas as VPNs alternativas** - Tailscale substitui tudo
2. **Mantenha apenas um tema LuCI** - Economiza 2-3MB
3. **Remova locales não utilizados** - Economiza 500KB-1MB
4. **Remova suporte Bluetooth/Wi-Fi se não usar** - Economiza 3-5MB
5. **Remova ferramentas de desenvolvimento** - Economiza 2-3MB

**Economia realista:** 8-12MB

Isso deve liberar espaço suficiente para Tailscale + LuCI + folga.

## Monitoramento de CPU e Clock

### Script de Monitoramento

O script `cpu_monitor.sh` monitora uso de CPU, temperatura, frequência e carga do processador.

```bash
# Copiar script para o roteador
scp cpu_monitor.sh root@router-ip:/tmp/

# Executar no roteador (snapshot)
ssh root@router-ip
cd /tmp
chmod +x cpu_monitor.sh
./cpu_monitor.sh

# Executar monitoramento contínuo
./cpu_monitor.sh continuous
```

### Informações Monitoradas

- **Frequência do processador**: Atual, máxima, mínima
- **Governor de CPU**: Modo de gerenciamento de energia
- **Temperatura**: Temperatura atual do processador
- **Uso de CPU**: Porcentagem de uso por core
- **Carga do sistema**: Load average
- **Uso de memória**: RAM disponível/usada
- **Top processos**: Processos mais intensivos
- **Uso do Tailscale**: CPU e memória do tailscaled

### Frequência do Processador (MT7628NN)

O MT7628NN opera em:
- **Frequência base**: 580MHz
- **Governor**: Ondemand (ajusta dinamicamente)
- **Gerenciamento de energia**: Automático

O script mostra se o processador está operando em frequência máxima ou se está sendo reduzido para economizar energia.

### Quando Monitorar

- **Após instalação do Tailscale**: Verificar impacto no sistema
- **Durante uso intenso**: Verificar se CPU está sobrecarregada
- **Se houver lentidão**: Identificar processos problemáticos
- **Para otimização**: Ajustar configurações baseado no uso
