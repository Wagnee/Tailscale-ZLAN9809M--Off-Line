# Recursos do Sistema - Tailscale + Modbus + MQTT

## Especificações do Hardware

### ZLAN9809M
- **Processador**: MediaTek MT7628NN (MIPS 24Kc, 580MHz)
- **Arquitetura**: mipsel_24kc (little-endian)
- **Flash**: 16MB total
  - ~11.5MB para firmware OpenWrt
  - ~4.5MB disponível para overlay (instalação de pacotes)
- **RAM**: 64MB ou 128MB (dependendo da versão)

## Análise de Espaço - Flash (Armazenamento)

### Espaço Base (após instalação limpa do OpenWrt)
- **Overlay disponível**: ~4.5MB
- **Espaço livre**: ~4.5MB

### Tailscale (versão compacta com XZ)
| Componente | Tamanho |
|------------|---------|
| tailscaled (binário XZ) | 4.9MB |
| scripts de init | ~10KB |
| configuração UCI | ~5KB |
| **Total Tailscale** | **~4.9MB** |

### Modbus + MQTT (opcional)
| Componente | Tamanho Real (IPK) |
|------------|-------------------|
| libmodbus (biblioteca) | 37KB |
| mosquitto-client (binários) | 35KB |
| modbus-daemon (Go, com UPX) | 671KB |
| mqtt-daemon (Go, com UPX) | 1.6MB |
| luci-app-modbus | 2.1KB |
| luci-app-mqtt | 2.2KB |
| configurações e scripts | ~20KB |
| **Total Modbus+MQTT** | **~2.4MB** |

### Cenários de Instalação

#### Cenário 1: Apenas Tailscale
- **Usado**: 4.9MB
- **Livre**: ~-0.4MB (excede limite)
- **Status**: ⚠️ Requer limpeza prévia

#### Cenário 2: Tailscale + Modbus + MQTT
- **Usado**: 4.9MB + 2.4MB = 7.3MB
- **Livre**: ~-2.8MB (excede limite)
- **Status**: ❌ Impossível sem limpeza prévia

#### Cenário 3: Tailscale (após cleanup) + Modbus + MQTT
- **Após cleanup**: ~8-12MB livres
- **Tailscale**: 4.9MB
- **Modbus+MQTT**: 2.4MB
- **Total usado**: 7.3MB
- **Livre**: ~0.7-4.7MB
- **Status**: ✅ Viável

## Análise de Memória RAM

### Uso Base (OpenWrt sem Tailscale)
- **Sistema base**: ~15-20MB
- **Serviços padrão**: ~5-10MB
- **Total base**: ~20-30MB
- **Livre**: 34-44MB (64MB) ou 98-108MB (128MB)

### Tailscale
- **tailscaled (idle)**: ~10-15MB
- **Tailscale em uso**: ~15-25MB
- **Total com Tailscale**: ~35-55MB
- **Livre**: 9-29MB (64MB) ou 73-93MB (128MB)

### Modbus Daemon
- **modbus-daemon (idle)**: ~5-8MB
- **Com polling ativo (1 tag/30s)**: ~8-10MB
- **Estado em memória**: ~1-2MB (depende do número de tags)
- **CPU**: <2% durante polling

### MQTT Daemon
- **mqtt-daemon (idle)**: ~5-8MB
- **Com conexão ativa**: ~8-10MB
- **Buffer de mensagens**: ~1-2MB
- **CPU**: <1% durante publicação

### Cenários de Uso de RAM

#### Cenário 1: Apenas Tailscale (idle)
- **Usado**: ~35-45MB
- **Livre**: 19-29MB (64MB) ou 83-93MB (128MB)
- **Status**: ✅ Confortável

#### Cenário 2: Tailscale + Modbus + MQTT (idle)
- **Usado**: ~45-65MB
- **Livre**: -1-19MB (64MB) ou 63-83MB (128MB)
- **Status**: ⚠️ Apertado em 64MB, OK em 128MB

#### Cenário 3: Tailscale + Modbus + MQTT (ativo - polling 30s)
- **Usado**: ~50-70MB
- **Livre**: -6-14MB (64MB) ou 58-78MB (128MB)
- **Status**: ⚠️ Apertado em 64MB, OK em 128MB

**Nota:** Para o caso de uso típico (ler 1 tag a cada 30s), o impacto na RAM é mínimo (~5-10MB adicional).

## Recomendações

### Para dispositivos com 64MB RAM
- **Recomendado**: Apenas Tailscale
- **Modbus+MQTT**: Não recomendado (pode causar OOM)
- **Alternativa**: Usar Modbus+MQTT em dispositivo separado

### Para dispositivos com 128MB RAM
- **Recomendado**: Tailscale + Modbus + MQTT
- **Status**: ✅ Viável
- **Nota**: Monitorar uso de memória

### Estratégia de Instalação

1. **Limpeza Prévia** (sempre executar antes):
   ```bash
   ./cleanup.sh
   ```

2. **Instalar Tailscale**:
   ```bash
   opkg install tailscale-zlan9809m-xz_*.ipk
   ```

3. **Verificar Espaço**:
   ```bash
   df -h /overlay
   free -h
   ```

4. **Instalar Modbus+MQTT** (opcional, apenas se espaço > 3MB):
   ```bash
   opkg install libmodbus_*.ipk
   opkg install mosquitto-client_*.ipk
   opkg install modbus-daemon_*.ipk
   opkg install mqtt-daemon_*.ipk
   ```

## Monitoramento de Recursos

### Verificar uso de Flash
```bash
df -h /overlay
```

### Verificar uso de RAM
```bash
free -h
```

### Monitorar processos
```bash
top
```

### Verificar uso por processo
```bash
ps | grep -E "tailscaled|modbus-daemon|mqtt-daemon"
```

## Otimizações Aplicadas

### Tailscale
- ✅ Compressão XZ (redução de 5.1MB para 4.9MB)
- ✅ Remoção de funcionalidades não essenciais
- ✅ Strip de símbolos de debug
- ✅ Build tags para reduzir tamanho

### Modbus Daemon
- ✅ Compilação estática com CGO
- ✅ UPX compressão (redução de 2.5MB para 671KB - 73%)
- ✅ Strip de símbolos
- ✅ ldflags -s -w
- ✅ Go 1.24.0 com GOMIPS=softfloat

### MQTT Daemon
- ✅ Compilação estática com CGO
- ✅ UPX compressão (redução de 6.1MB para 1.6MB - 74%)
- ✅ Strip de símbolos
- ✅ ldflags -s -w
- ✅ Go 1.24.0 com GOMIPS=softfloat

### Interfaces LuCI
- ✅ Código Lua otimizado
- ✅ Sem dependências externas
- ✅ Templates minimalistas

## Limitações Conhecidas

### Flash (4.5MB disponível)
- ⚠️ Não é possível instalar Tailscale + Modbus + MQTT sem cleanup prévio
- ⚠️ Espaço limitado para logs e estado persistente
- ⚠️ Atualizações podem requerer reinstalação

### RAM (64MB)
- ⚠️ Tailscale + Modbus + MQTT pode causar OOM
- ⚠️ Número limitado de tags Modbus simultâneas
- ⚠️ Buffer MQTT limitado

### Performance
- ⚠️ Polling Modbus frequente pode afetar performance
- ⚠️ Conexão Tailscale pode consumir CPU durante handshakes
- ⚠️ Processador 580MHz é limitado para múltiplos daemons

## Tabela de Compatibilidade

| Configuração | Flash | RAM (64MB) | RAM (128MB) | Status |
|--------------|-------|------------|-------------|--------|
| OpenWrt base | ✅ | ✅ | ✅ | OK |
| + Tailscale | ⚠️ | ✅ | ✅ | Requer cleanup |
| + Modbus+MQTT | ⚠️ | ⚠️ | ✅ | Requer cleanup |
| Tailscale+Modbus+MQTT (pós-cleanup) | ⚠️ | ⚠️ | ✅ | Viável apenas 128MB |

**Nota:** Para o caso de uso típico (1 tag/30s), o Modbus+MQTT é viável em 64MB RAM com Tailscale, mas monitoramento é recomendado.

## Conclusão

O projeto é **viável para dispositivos com 128MB RAM** com Tailscale + Modbus + MQTT instalados.

Para dispositivos com **64MB RAM**:
- **Tailscale apenas**: ✅ Recomendado
- **Tailscale + Modbus+MQTT**: ⚠️ Viável para caso de uso leve (1 tag/30s)
- **Modbus+MQTT intenso**: ❌ Não recomendado
- **Alternativa**: Usar Modbus+MQTT em dispositivo separado conectado via Tailscale

## Caso de Uso Típico

**Configuração:**
- 1 dispositivo Modbus TCP
- 1 tag sendo lida a cada 30 segundos
- Publicação em broker MQTT

**Recursos consumidos:**
- Flash: 2.4MB
- RAM: ~10-15MB adicional
- CPU: <5% durante polling

**Status:** ✅ Viável mesmo em 64MB RAM
