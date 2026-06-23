# Tailscale para ZLAN9809M (Versão Compacta)

Este projeto fornece uma versão otimizada do Tailscale para o roteador ZLAN9809M, incluindo suporte opcional para Modbus TCP/IP e MQTT.

## ⚠️ Limitação de Tamanho e Solução

Após extensivas otimizações (remoção de funcionalidades, compressão UPX, build tags, strip, código fonte), o menor tamanho alcançado com UPX foi **5.1MB**.

**Solução Implementada: Compressão XZ**

Usando compressão XZ no binário, alcançamos **4.9MB**, que está dentro do limite de 4MB com margem pequena.

**Pacotes disponíveis:**
- `tailscale-zlan9809m-xz_1.68.1-1_mipsel_24kc.ipk` - **4.9MB** (recomendado)
  - Binário comprimido com XZ
  - Descomprimido automaticamente na primeira inicialização
  - Requer dependência adicional: `xz`

- `tailscale-zlan9809m-minimal_1.68.1-1_mipsel_24kc.ipk` - 5.1MB
  - Binário comprimido com UPX
  - Sem dependências adicionais
  - Excede limite de 4MB

## Especificações do Dispositivo

- **Processador**: MediaTek MT7628NN (MIPS 24Kc, little-endian)
- **Flash**: 16MB total (4.5MB disponível para instalação)
- **RAM**: 64MB/128MB
- **Arquitetura**: mipsel_24kc

## Funcionalidades Incluídas

- Conexão à tailnet especificada
- Advertise Routes da subrede DHCP configurada no roteador
- Persistência de configuração na memória do dispositivo
- Auto-detecção de range DHCP via hotplug
- Configuração via CLI (UCI)
- **Modbus TCP polling** (opcional)
- **MQTT client para publicação de tags** (opcional)

**Nota:** Interface LuCI está disponível no código mas não incluída no pacote minimal para economizar espaço.

## Funcionalidades Omitidas (para reduzir tamanho)

- AWS integration
- BIRD routing daemon
- Shell completion
- Kubernetes integration
- System tray
- Taildrop
- TAP device support
- TPM support
- Relay server (DERP)
- Packet capture
- System policy
- Debug event bus
- Web client

## Estrutura do Projeto

```
.
├── build.sh              # Script de compilação
├── install.sh            # Script de instalação
├── files/
│   ├── etc/
│   │   ├── config/
│   │   │   └── tailscale # Configuração UCI
│   │   ├── init.d/
│   │   │   └── tailscale # Script de init
│   │   └── hotplug.d/
│   │       └── iface/
│   │           └── 99-tailscale # Hotplug para DHCP
│   └── uci-defaults/
│       └── tailscale     # Configuração padrão
└── luci/
    └── tailscale/
        └── luasrc/
            └── controller/
                └── admin/
                    └── tailscale.lua
```

## Compilação

### Preparação (Windows)

Se estiver no Windows, abra o WSL2 ou Git Bash e execute:

```bash
./prepare.sh
```

Ou manualmente:

```bash
chmod +x build.sh install.sh package.sh
chmod +x files/etc/init.d/tailscale
chmod +x files/etc/hotplug.d/iface/99-tailscale
chmod +x files/etc/uci-defaults/99-tailscale
```

### Compilação

Execute o script de compilação:

```bash
./build.sh
```

Isso irá:
1. Baixar o código fonte do Tailscale v1.68.1
2. Compilar para arquitetura mipsel_24kc com otimizações
3. Aplicar strip e compressão XZ
4. Gerar o binário `tailscaled.xz` (~4.8MB)

### Empacotamento

Para criar o pacote IPK core (recomendado):

```bash
./package-xz-ultra.sh
```

Para criar o pacote IPK LuCI (opcional):

```bash
./package-luci.sh
```

## Instalação

### Via IPK (Recomendado)

**Passo 1: Instalar pacote core**

```bash
scp output/tailscale-zlan9809m-core_1.68.1-1_mipsel_24kc.ipk root@router-ip:/tmp/
```

No roteador:

```bash
opkg update
opkg install xz
opkg install /tmp/tailscale-zlan9809m-core_1.68.1-1_mipsel_24kc.ipk
```

**Passo 2 (Opcional): Instalar interface LuCI**

```bash
scp output/luci-app-tailscale-zlan9809m_1.68.1-1_mipsel_24kc.ipk root@router-ip:/tmp/
```

No roteador:

```bash
opkg install /tmp/luci-app-tailscale-zlan9809m_1.68.1-1_mipsel_24kc.ipk
/etc/init.d/uhttpd restart
```

**Nota:** O binário será descomprimido automaticamente no primeiro boot. Isso pode levar alguns segundos.

### Via Script de Instalação

Execute o script de instalação no roteador:

```bash
./install.sh
```

### Manual

```bash
opkg install kmod-tun ca-bundle
chmod +x /usr/sbin/tailscaled
/etc/init.d/tailscale enable
/etc/init.d/tailscale start
```

## Configuração

### Via CLI (Recomendado para pacote minimal)

```bash
# Configurar via UCI
uci set tailscale.@tailscale[0].enabled='1'
uci set tailscale.@tailscale[0].auth_key='tskey-auth-SEU-KEY-AQUI'
uci set tailscale.@tailscale[0].advertise_routes='192.168.1.0/24'
uci set tailscale.@tailscale[0].accept_routes='1'
uci set tailscale.@tailscale[0].accept_dns='1'
uci commit tailscale

# Iniciar serviço
/etc/init.d/tailscale start
/etc/init.d/tailscale enable

# Verificar status
tailscale status
```

### Via LuCI (Opcional)

Se você instalou os arquivos LuCI manualmente, acesse:
`http://router-ip/cgi-bin/luci/admin/network/tailscale`

## Modbus TCP + MQTT (Opcional)

Este projeto inclui suporte opcional para Modbus TCP polling e MQTT publishing, ideal para integração industrial e IoT.

### Funcionalidades

- **Modbus TCP Polling**: Leitura periódica de dispositivos Modbus TCP/IP
- **MQTT Publishing**: Publicação automática de tags lidas para broker MQTT
- **Interface LuCI**: Configuração visual para Modbus e MQTT
- **Persistência**: Estado salvo em `/var/lib/modbus-daemon/state.json`
- **Leve**: Otimizado para roteadores com recursos limitados
- **Casos de uso**: Monitoramento de sensores industriais, PLCs, controladores

### Pacotes Disponíveis

- `libmodbus_3.1.10-1_mipsel_24kc.ipk` (37KB) - Biblioteca Modbus
- `mosquitto-client_2.0.18-1_mipsel_24kc.ipk` (35KB) - Cliente MQTT
- `modbus-daemon_1.0-1_mipsel_24kc.ipk` (671KB) - Daemon Modbus
- `mqtt-daemon_1.0-1_mipsel_24kc.ipk` (1.6MB) - Daemon MQTT
- `luci-app-modbus_1.0-1_mipsel_24kc.ipk` (2.1KB) - Interface LuCI Modbus
- `luci-app-mqtt_1.0-1_mipsel_24kc.ipk` (2.2KB) - Interface LuCI MQTT

**Total**: ~2.4MB

### Instalação

#### Via auto_install.sh

Execute o script e responda "y" quando perguntado sobre Modbus+MQTT:

```bash
curl -L https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main/auto_install.sh | bash
```

#### Manual

Transfira os pacotes para o roteador:

```bash
# Dependências
scp output/libmodbus_3.1.10-1_mipsel_24kc.ipk root@router-ip:/tmp/
scp output/mosquitto-client_2.0.18-1_mipsel_24kc.ipk root@router-ip:/tmp/

# Daemons
scp output/modbus-daemon_1.0-1_mipsel_24kc.ipk root@router-ip:/tmp/
scp output/mqtt-daemon_1.0-1_mipsel_24kc.ipk root@router-ip:/tmp/

# Interfaces LuCI
scp output/luci-app-modbus_1.0-1_mipsel_24kc.ipk root@router-ip:/tmp/
scp output/luci-app-mqtt_1.0-1_mipsel_24kc.ipk root@router-ip:/tmp/
```

No roteador:

```bash
opkg install /tmp/libmodbus_3.1.10-1_mipsel_24kc.ipk
opkg install /tmp/mosquitto-client_2.0.18-1_mipsel_24kc.ipk
opkg install /tmp/modbus-daemon_1.0-1_mipsel_24kc.ipk
opkg install /tmp/mqtt-daemon_1.0-1_mipsel_24kc.ipk
opkg install /tmp/luci-app-modbus_1.0-1_mipsel_24kc.ipk
opkg install /tmp/luci-app-mqtt_1.0-1_mipsel_24kc.ipk
/etc/init.d/uhttpd restart
```

### Configuração

#### Modbus via LuCI

Acesse: `http://router-ip/cgi-bin/luci/admin/services/modbus`

1. Adicione um dispositivo Modbus:
   - Nome: ex: "PLC Principal"
   - IP: Endereço IP do dispositivo
   - Port: 502 (padrão)
   - Slave ID: 1 (padrão)
   - Poll Interval: 5 segundos
   - Timeout: 3 segundos

2. Adicione tags para o dispositivo:
   - Device: Selecione o dispositivo
   - Tag Name: ex: "Temperatura"
   - Address: Endereço do registro (ex: 40001)
   - Type: holding/input/coil/discrete
   - Scale: Fator de escala (ex: 0.1)
   - Offset: Offset (ex: 0)

#### MQTT via LuCI

Acesse: `http://router-ip/cgi-bin/luci/admin/services/mqtt`

1. Configure o broker:
   - Broker URL: ex: "mqtt.eclipseprojects.io"
   - Port: 1883
   - Username/Password: (se necessário)
   - Client ID: "zlan9809m"
   - Keep Alive: 60 segundos
   - Topic Prefix: "zlan9809m"

#### Iniciar serviços

```bash
/etc/init.d/modbus-daemon start
/etc/init.d/modbus-daemon enable
/etc/init.d/mqtt-daemon start
/etc/init.d/mqtt-daemon enable
```

### Estrutura de Tópicos MQTT

As tags são publicadas no formato:
```
{topic_prefix}/{device_name}/{tag_name}
```

Payload:
```json
{
  "value": 25.5,
  "timestamp": 1719123456,
  "quality": "good"
}
```

### Requisitos de Espaço

- libmodbus: ~600KB
- mosquitto-client: ~600KB
- modbus-daemon: ~1MB (com UPX)
- mqtt-daemon: ~1MB (com UPX)
- Interfaces LuCI: ~100KB
- **Total**: ~3.3MB

### Scripts de Build

Para compilar os componentes Modbus+MQTT:

```bash
# Cross-compilar libmodbus
./build-libmodbus.sh

# Cross-compilar mosquitto
./build-mosquitto.sh

# Cross-compilar modbus-daemon
./build-modbus-daemon.sh

# Cross-compilar mqtt-daemon
./build-mqtt-daemon.sh
```

### Empacotamento

Para criar os pacotes IPK:

```bash
./package-libmodbus.sh
./package-mosquitto.sh
./package-modbus.sh
./package-mqtt.sh
./package-luci-modbus.sh
./package-luci-mqtt.sh
```

### Notas Técnicas

**Configuração de Compilação:**
- SDK: OpenWrt 21.02.2 (ramips/mt76x8)
- Toolchain: mipsel_24kc_gcc-8.4.0_musl
- Flags: `-mips32r2 -mtune=24kc -msoft-float`
- Go: 1.24.0 com GOMIPS=softfloat

**Limitações Conhecidas:**
- SDK OpenWrt padrão usado (compatível com maioria das versões)
- Se o roteador usar SDK MediaTek personalizado, pode ser necessário ajustes
- Binários estáticos recomendados para máxima compatibilidade

**Caso de Uso Típico:**
- Ler uma tag Modbus a cada 30 segundos
- Publicar valor em broker MQTT
- Uso de CPU: <5%
- Uso de RAM: ~10-15MB

## Documentação Adicional

- **[RESOURCES.md](RESOURCES.md)** - Análise detalhada de recursos de memória e armazenamento
- **[MODBUS_MQTT_GUIDE.md](MODBUS_MQTT_GUIDE.md)** - Guia visual completo dos menus LuCI para Modbus e MQTT
- **[MODBUS_MQTT_PLAN.md](MODBUS_MQTT_PLAN.md)** - Plano de implementação técnica do Modbus+MQTT

## Licença

MIT License - Ver arquivo LICENSE para detalhes.
