# Guia de Criação de Firmware Customizado

## Objetivo

Criar uma imagem de firmware customizada do OpenWrt que já inclua:
- Tailscale (core + LuCI)
- Modbus (libmodbus + modbus-daemon + LuCI)
- MQTT (mosquitto-client + mqtt-daemon + LuCI)
- Configurações pré-definidas

Assim, ao resetar o roteador (botão de reset), ele recupera esta imagem customizada em vez da original de fábrica.

## Opção 1: Image Builder do OpenWrt (Recomendado)

### Pré-requisitos

1. Baixar o Image Builder para ramips/mt76x8 (OpenWrt 21.02.2):
```bash
cd ~/openwrt
wget https://downloads.openwrt.org/releases/21.02.2/targets/ramips/mt76x8/openwrt-imagebuilder-21.02.2-ramips-mt76x8.Linux-x86_64.tar.xz
tar -xf openwrt-imagebuilder-21.02.2-ramips-mt76x8.Linux-x86_64.tar.xz
cd openwrt-imagebuilder-21.02.2-ramips-mt76x8.Linux-x86_64
```

2. Copiar pacotes IPK compilados para o Image Builder:
```bash
mkdir -p packages/base
cp /path/to/Tailscale-ZLAN9809M--Off-Line/output/*.ipk packages/base/
```

### Criar Imagem Customizada

```bash
# Criar imagem com pacotes incluídos
make image PROFILE=zlan_zlan9809m \
  PACKAGES="tailscale-zlan9809m-core luci-app-tailscale-zlan9809m \
            libmodbus mosquitto-client \
            modbus-daemon mqtt-daemon \
            luci-app-modbus luci-app-mqtt" \
  FILES=files/
```

### Configurações Padrão

Criar diretório `files/` com configurações pré-definidas:

```
files/
├── etc/
│   ├── config/
│   │   ├── tailscale
│   │   ├── modbus
│   │   └── mqtt
│   └── uci-defaults/
│       └── 99-custom-config
```

**Exemplo: files/etc/config/tailscale**
```uci
config tailscale 'tailscale'
    option enabled '1'
    option accept_routes '1'
    option accept_dns '1'
    option advertise_exit_node '0'
```

**Exemplo: files/etc/uci-defaults/99-custom-config**
```bash
#!/bin/sh
# Configurações padrão após primeiro boot

# Configurar Tailscale (sem auth key - usuário deve configurar)
uci set tailscale.@tailscale[0].enabled='1'
uci set tailscale.@tailscale[0].accept_routes='1'
uci set tailscale.@tailscale[0].accept_dns='1'
uci commit tailscale

# Configurar Modbus (exemplo)
uci set modbus.@device[0].enabled='0'
uci set modbus.@device[0].name='PLC Principal'
uci set modbus.@device[0].ip='192.168.1.100'
uci set modbus.@device[0].port='502'
uci set modbus.@device[0].slave_id='1'
uci set modbus.@device[0].poll_interval='60'
uci set modbus.@device[0].timeout='5'
uci commit modbus

# Configurar MQTT (exemplo)
uci set mqtt.@mqtt[0].enabled='0'
uci set mqtt.@mqtt[0].broker='mqtt.eclipseprojects.io'
uci set mqtt.@mqtt[0].port='1883'
uci set mqtt.@mqtt[0].client_id='zlan9809m'
uci set mqtt.@mqtt[0].keepalive='60'
uci set mqtt.@mqtt[0].topic_prefix='zlan9809m'
uci commit mqtt

exit 0
```

### Flash da Imagem Customizada

A imagem gerada estará em:
```
bin/targets/ramips/mt76x8/openwrt-21.02.2-ramips-mt76x8-zlan_zlan9809m-squashfs-sysupgrade.bin
```

Para flashar:
1. Acesse LuCI → System → Backup / Flash Firmware
2. Faça upload do arquivo `.bin`
3. Clique em "Flash image"

## Opção 2: Backup/Restore Automático

Se não quiser criar firmware customizado, pode automatizar backup/restore:

### Script de Backup Automático

```bash
#!/bin/bash
# backup-config.sh - Backup de configurações

BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

# Backup de configurações UCI
tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" /etc/config/

# Backup de pacotes instalados
opkg list-installed > "$BACKUP_DIR/packages_$DATE.txt"

# Upload para servidor remoto (opcional)
# scp "$BACKUP_DIR/config_$DATE.tar.gz" user@server:/backups/

echo "Backup concluído: $BACKUP_DIR/config_$DATE.tar.gz"
```

### Script de Restore Automático

```bash
#!/bin/bash
# restore-config.sh - Restore de configurações

BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
    echo "Uso: $0 <arquivo_backup.tar.gz>"
    exit 1
fi

# Restore de configurações
tar -xzf "$BACKUP_FILE" -C /

# Reinstalar pacotes
PACKAGES_FILE="${BACKUP_FILE%.tar.gz}.txt"
if [ -f "$PACKAGES_FILE" ]; then
    opkg update
    while read -r package; do
        opkg install "$package"
    done < "$PACKAGES_FILE"
fi

# Reiniciar serviços
/etc/init.d/tailscale restart
/etc/init.d/modbus-daemon restart
/etc/init.d/mqtt-daemon restart

echo "Restore concluído"
```

## Opção 3: OverlayFS Persistente

Usar partição externa (USB/SD) para armazenar configurações:

### Configurar Overlay Externo

```bash
# Formatar USB/SD como ext4
mkfs.ext4 /dev/sdX1

# Montar em /overlay
mount /dev/sdX1 /overlay

# Copiar overlay atual
tar -C /overlay -c . | tar -C / -x /

# Adicionar ao fstab
echo "/dev/sdX1 /overlay ext4 defaults 0 0" >> /etc/fstab
```

## Limitações e Considerações

### ⚠️ Limitações do Image Builder

1. **Auth Key do Tailscale**: Não pode incluir auth key na imagem (segurança)
   - Solução: Usar uci-defaults para configurar, usuário deve adicionar auth key após boot

2. **Configurações Específicas**: IP do dispositivo Modbus, broker MQTT
   - Solução: Usar uci-defaults com configurações de exemplo, usuário deve ajustar

3. **Tamanho da Imagem**: Incluir todos os pacotes aumenta tamanho
   - Solução: Usar apenas pacotes essenciais, outros via opkg

### ⚠️ Reset de Fábrica

O botão de reset normalmente:
1. Formata o overlay (configurações)
2. Restaura configurações de fábrica do firmware
3. **NÃO** reinstala o firmware

Se você flashar firmware customizado:
- Reset de fábrica: Restaura configurações padrão do firmware customizado
- **NÃO** volta ao firmware original de fábrica

Para voltar ao firmware original:
- Deve flashar novamente o firmware original do fabricante

## Recomendação

**Para seu caso de uso:**

1. **Se o roteador for para produção fixa:**
   - Criar firmware customizado com Image Builder
   - Incluir todos os pacotes
   - Usar uci-defaults para configurações de exemplo
   - Flashar firmware customizado

2. **Se o roteador for para testes/desenvolvimento:**
   - Usar script auto_install.sh
   - Criar script de backup automático
   - Usar restore manual quando necessário

## Passos Práticos para Firmware Customizado

### 1. Baixar Image Builder
```bash
cd ~/openwrt
wget https://downloads.openwrt.org/releases/21.02.2/targets/ramips/mt76x8/openwrt-imagebuilder-21.02.2-ramips-mt76x8.Linux-x86_64.tar.xz
tar -xf openwrt-imagebuilder-21.02.2-ramips-mt76x8.Linux-x86_64.tar.xz
cd openwrt-imagebuilder-21.02.2-ramips-mt76x8.Linux-x86_64
```

### 2. Preparar Pacotes e Configurações
```bash
mkdir -p packages/base files/etc/config files/etc/uci-defaults
cp /path/to/output/*.ipk packages/base/
```

### 3. Criar Configurações Padrão
```bash
# Criar files/etc/config/tailscale
cat > files/etc/config/tailscale <<'EOF'
config tailscale 'tailscale'
    option enabled '1'
    option accept_routes '1'
    option accept_dns '1'
EOF

# Criar files/etc/config/modbus
cat > files/etc/config/modbus <<'EOF'
config modbus 'device1'
    option enabled '0'
    option name ''
    option ip ''
    option port '502'
    option slave_id '1'
    option poll_interval '60'
    option timeout '5'
EOF

# Criar files/etc/config/mqtt
cat > files/etc/config/mqtt <<'EOF'
config mqtt 'client'
    option enabled '0'
    option broker 'mqtt.eclipseprojects.io'
    option port '1883'
    option username ''
    option password ''
    option client_id 'zlan9809m'
    option keepalive '60'
    option topic_prefix 'zlan9809m'
EOF
```

### 4. Criar Script uci-defaults
```bash
cat > files/etc/uci-defaults/99-custom-config <<'EOF'
#!/bin/sh
# Configurações padrão após primeiro boot

# Configurar rede (opcional)
uci set network.lan.ipaddr='192.168.1.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network

exit 0
EOF
chmod +x files/etc/uci-defaults/99-custom-config
```

### 5. Compilar Imagem
```bash
make image PROFILE=zlan_zlan9809m \
  PACKAGES="tailscale-zlan9809m-core luci-app-tailscale-zlan9809m \
            libmodbus mosquitto-client \
            modbus-daemon mqtt-daemon \
            luci-app-modbus luci-app-mqtt \
            kmod-tun ca-bundle xz" \
  FILES=files/
```

### 6. Flashar Imagem
A imagem estará em:
```
bin/targets/ramips/mt76x8/openwrt-21.02.2-ramips-mt76x8-zlan_zlan9809m-squashfs-sysupgrade.bin
```

Flashar via LuCI ou sysupgrade:
```bash
sysupgrade -v bin/targets/ramips/mt76x8/openwrt-21.02.2-ramips-mt76x8-zlan_zlan9809m-squashfs-sysupgrade.bin
```

## Conclusão

**Sim, é possível criar firmware customizado** que inclua todos os pacotes e configurações. Ao resetar o roteador, ele recuperará essa imagem customizada.

**Recomendação:** Use Image Builder do OpenWrt para criar firmware customizado para produção. Para testes, use script auto_install.sh + backup/restore manual.
