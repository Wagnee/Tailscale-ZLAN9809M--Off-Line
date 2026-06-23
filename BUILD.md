# Guia de Compilação

Este documento descreve o processo completo de compilação e empacotamento para o ZLAN9809M.

## Requisitos

### Hardware
- Processador: MediaTek MT7628NN (MIPS 24Kc, little-endian)
- RAM: 64MB/128MB
- Flash: 16MB total (4.5MB disponível para instalação)

### Software
- Linux/WSL com bash
- Go 1.24.0+ (para daemons Go)
- OpenWrt SDK 21.02.2 (ramips/mt76x8)
- CMake 3.28+ (para mosquitto)
- Autoconf, Automake, Libtool (para libmodbus)
- UPX 4.2+ (opcional, para compressão)

## Configuração do Processador

**Especificações do ZLAN9809M:**
- Target: ramips
- Subtarget: mt76x8
- CPU: MediaTek MT7628NN (MIPS 24Kc @ ~580MHz)
- Flags de compilação: `-mips32r2 -mtune=24kc -msoft-float`

## Compilação do Tailscale

### Preparação do Ambiente

```bash
# Dar permissão aos scripts
chmod +x build.sh install.sh package.sh
chmod +x files/etc/init.d/tailscale
chmod +x files/etc/hotplug.d/iface/99-tailscale
chmod +x files/etc/uci-defaults/99-tailscale
```

### Compilação

```bash
./build.sh
```

Este script:
1. Baixa o código fonte do Tailscale v1.68.1
2. Compila para arquitetura mipsel_24kc com otimizações
3. Aplica strip para remover símbolos de debug
4. Aplica compressão XZ para reduzir tamanho
5. Gera o binário `tailscaled.xz` (~4.8MB)

### Empacotamento

```bash
# Pacote core com compressão XZ (recomendado)
./package-xz-ultra.sh

# Pacote minimal com UPX
./package-minimal.sh

# Pacote LuCI (opcional)
./package-luci.sh
```

## Compilação do Modbus + MQTT

### Dependências

Instale as dependências necessárias no WSL:

```bash
sudo apt-get update
sudo apt-get install -y autoconf automake libtool cmake
```

### Compilação da Biblioteca Modbus

```bash
./build-libmodbus.sh
```

Este script:
1. Baixa o OpenWrt SDK 21.02.2 (ramips/mt76x8)
2. Baixa libmodbus 3.1.10
3. Configura com flags: `-mips32r2 -mtune=24kc`
4. Compila para mipsel_24kc
5. Gera `libmodbus-3.1.10-mipsel_24kc.tar.gz` (~36KB)

### Compilação do Mosquitto

```bash
./build-mosquitto.sh
```

Este script:
1. Baixa o OpenWrt SDK 21.02.2 (ramips/mt76x8)
2. Baixa mosquitto 2.0.18
3. Configura com cmake desabilitando TLS e threading
4. Compila para mipsel_24kc
5. Gera `mosquitto-client-2.0.18-mipsel_24kc.tar.gz` (~35KB)

### Compilação do Modbus Daemon (Go)

```bash
./build-modbus-daemon.sh
```

Este script:
1. Baixa Go 1.24.0
2. Baixa o OpenWrt SDK 21.02.2 (ramips/mt76x8)
3. Configura cross-compilação Go:
   - GOOS=linux
   - GOARCH=mipsle
   - GOMIPS=softfloat
4. Baixa dependências Go (github.com/goburrow/modbus)
5. Compila com flags: `-ldflags="-s -w"`
6. Comprime com UPX (se disponível)
7. Gera `modbus-daemon-mipsel_24kc.tar.gz` (~671KB)

### Compilação do MQTT Daemon (Go)

```bash
./build-mqtt-daemon.sh
```

Este script:
1. Baixa Go 1.24.0
2. Baixa o OpenWrt SDK 21.02.2 (ramips/mt76x8)
3. Configura cross-compilação Go:
   - GOOS=linux
   - GOARCH=mipsle
   - GOMIPS=softfloat
4. Baixa dependências Go (github.com/eclipse/paho.mqtt.golang)
5. Compila com flags: `-ldflags="-s -w"`
6. Comprime com UPX (se disponível)
7. Gera `mqtt-daemon-mipsel_24kc.tar.gz` (~1.6MB)

## Empacotamento IPK

### Empacotamento do Libmodbus

```bash
./package-libmodbus.sh
```

Gera: `libmodbus_3.1.10-1_mipsel_24kc.ipk` (~37KB)

### Empacotamento do Mosquitto

```bash
./package-mosquitto.sh
```

Gera: `mosquitto-client_2.0.18-1_mipsel_24kc.ipk` (~35KB)

### Empacotamento do Modbus Daemon

```bash
./package-modbus.sh
```

Gera: `modbus-daemon_1.0-1_mipsel_24kc.ipk` (~671KB)

### Empacotamento do MQTT Daemon

```bash
./package-mqtt.sh
```

Gera: `mqtt-daemon_1.0-1_mipsel_24kc.ipk` (~1.6MB)

### Empacotamento da Interface LuCI Modbus

```bash
./package-luci-modbus.sh
```

Gera: `luci-app-modbus_1.0-1_mipsel_24kc.ipk` (~2.1KB)

### Empacotamento da Interface LuCI MQTT

```bash
./package-luci-mqtt.sh
```

Gera: `luci-app-mqtt_1.0-1_mipsel_24kc.ipk` (~2.2KB)

## Estrutura dos Pacotes IPK

### Formato IPK

Os pacotes IPK são arquivos tar.gz com a seguinte estrutura:

```
package.ipk
├── CONTROL/
│   ├── control        # Metadados do pacote
│   ├── postinst       # Script pós-instalação
│   └── prerm          # Script pré-remoção
├── usr/
│   ├── bin/           # Binários executáveis
│   ├── lib/           # Bibliotecas compartilhadas
│   └── include/       # Arquivos de cabeçalho
└── etc/
    ├── init.d/        # Scripts de init
    └── config/        # Arquivos de configuração UCI
```

### Exemplo: modbus-daemon

```
modbus-daemon_1.0-1_mipsel_24kc.ipk
├── CONTROL/
│   ├── control
│   │   Package: modbus-daemon
│   │   Version: 1.0-1
│   │   Architecture: mipsel_24kc
│   │   Maintainer: Tailscale for ZLAN9809M Project
│   │   Section: utils
│   │   Priority: optional
│   │   Description: Modbus TCP polling daemon for ZLAN9809M
│   │   Depends: libmodbus
│   │   License: MIT
│   ├── postinst
│   │   #!/bin/sh
│   │   /etc/init.d/modbus-daemon enable
│   │   /etc/init.d/modbus-daemon start
│   └── prerm
│       #!/bin/sh
│       /etc/init.d/modbus-daemon stop
├── usr/
│   └── bin/
│       └── modbus-daemon
└── etc/
    ├── init.d/
    │   └── modbus-daemon
    └── config/
        └── modbus
```

## Troubleshooting

### Erro: SSL Certificate

Se ocorrer erro de certificado SSL ao baixar SDK ou fontes:

```bash
# Os scripts já incluem --no-check-certificate
# Se ainda falhar, desabilite verificação SSL temporariamente
export wget_options="--no-check-certificate"
```

### Erro: 404 Not Found

Se o SDK do OpenWrt não for encontrado:

1. Verifique a URL no script de build
2. Use uma versão alternativa do SDK disponível em archive.openwrt.org
3. Atualize a variável TOOLCHAIN_URL no script

### Erro: autoreconf: not found

Instale as dependências de build:

```bash
sudo apt-get install -y autoconf automake libtool
```

### Erro: cmake not found

Instale o cmake:

```bash
sudo apt-get install -y cmake
```

### Erro: ipkg-build: command not found

Os scripts de empacotamento foram atualizados para usar tar diretamente em vez de ipkg-build. Se você ainda tiver problemas, verifique se o script está usando o método correto.

### Erro: Go version too old

Se o Go exigir uma versão mais nova:

1. Atualize a variável GO_VERSION no script para 1.24.0+
2. Reexecute o script de build

### Erro: STAGING_DIR not defined

Este aviso pode ser ignorado. É uma mensagem informativa do toolchain do OpenWrt.

## Otimizações Aplicadas

### Tailscale

- Remoção de funcionalidades não essenciais
- Build tags para excluir código não utilizado
- Strip para remover símbolos de debug
- Compressão XZ para reduzir tamanho
- Resultado: 4.9MB (dentro do limite de 4MB)

### Daemons Go (Modbus/MQTT)

- Compilação estática onde possível
- Flags de linker: `-ldflags="-s -w"` para remover informações de debug
- Compressão UPX para reduzir tamanho
- Resultado: ~671KB (modbus), ~1.6MB (mqtt)

### Bibliotecas C (libmodbus, mosquitto)

- Flags de otimização: `-O2 -pipe -mno-branch-likely -mips32r2 -mtune=24kc`
- Strip para remover símbolos de debug
- Desabilitação de funcionalidades não usadas (TLS, threading)
- Resultado: ~36KB (libmodbus), ~35KB (mosquitto)

## Notas de Compatibilidade

### SDK OpenWrt

Os scripts usam o SDK OpenWrt 21.02.2 padrão para ramips/mt76x8. Isso é compatível com a maioria das versões do OpenWrt.

Se o seu roteador usa um SDK personalizado da MediaTek, você pode precisar:

1. Obter o SDK específico do fabricante
2. Atualizar a variável TOOLCHAIN_URL nos scripts
3. Verificar a compatibilidade das bibliotecas do sistema

### Binários Estáticos

Para máxima compatibilidade, considere compilar com binários estáticos:

```bash
# Para libmodbus
./configure --enable-static --disable-shared

# Para mosquitto
cmake -DWITH_STATIC_LIBRARIES=ON -DWITH_SHARED_LIBRARIES=OFF
```

## Verificação

### Verificar Arquitetura do Binário

```bash
file output/modbus-daemon-mipsel_24kc.tar.gz
tar -tzf output/modbus-daemon-mipsel_24kc.tar.gz
tar -xzf output/modbus-daemon-mipsel_24kc.tar.gz -C /tmp
file /tmp/usr/bin/modbus-daemon
# Deve mostrar: ELF 32-bit LSB executable, MIPS, MIPS32 version 1 (MIPS32r2)
```

### Verificar Dependências

```bash
# No roteador
opkg info modbus-daemon
opkg depends modbus-daemon
```

### Verificar Tamanho

```bash
ls -lh output/*.ipk
```

## Referências

- [OpenWrt SDK](https://openwrt.org/docs/guide-developer/using-the-sdk)
- [Cross-compilation](https://openwrt.org/docs/guide-developer/cross-compile)
- [MIPS Architecture](https://www.mips.com/)
- [Go Cross-compilation](https://go.dev/doc/install/source)
- [IPK Format](https://openwrt.org/docs/guide-developer/packages)
