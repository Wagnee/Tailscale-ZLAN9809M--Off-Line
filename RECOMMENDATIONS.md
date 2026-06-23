# Recomendações para Caso de Uso Específico

## Caso de Uso
- Tailscale (independente de 4G/WiFi/cabo)
- Polling de 3 tags Modbus a cada 30s
- Publicação MQTT das tags
- Keepalive periódico com métricas do sistema

## Viabilidade do Hardware
- **CPU**: MediaTek MT7628NN (MIPS 24Kc, 580MHz) - ✅ Adequado
- **RAM**: 64MB - ⚠️ Apertado mas viável
- **Flash**: 4.5MB - ⚠️ Requer cleanup prévio
- **Custo**: Baixo - ✅ Excelente custo-benefício

## Recursos Estimados
- **RAM**: ~52-67MB de 64MB (Tailscale + Modbus + MQTT + Keepalive)
- **CPU**: <8% durante operação normal (polling 1/min)
- **Flash**: ~7-8MB instalado (requer cleanup prévio)
- **Network**: Tráfego leve (<2MB/hora com polling 1/min)

## Recomendações de Implementação

### 1. Daemon de Keepalive (Novo Componente)

Criar `system-monitor-daemon` em Go:

```go
// Funções principais:
- Coletar métricas do sistema (RAM, CPU, Flash)
- Detectar tipo de conexão (cabo, WiFi, 4G)
- Verificar status dos serviços (Tailscale, Modbus, MQTT)
- Publicar em MQTT em intervalo configurável (5-10 min)
```

**Payload JSON:**
```json
{
  "hostname": "zlan9809m",
  "uptime": 86400,
  "ram_total_mb": 64,
  "ram_used_mb": 52,
  "ram_free_mb": 12,
  "ram_percent": 81,
  "cpu_percent": 3.2,
  "flash_total_mb": 4.5,
  "flash_used_mb": 7.8,
  "flash_free_mb": -3.3,
  "connection_type": "4g",
  "connection_interface": "ppp0",
  "tailscale_status": "connected",
  "tailscale_ip": "100.x.x.x",
  "modbus_status": "connected",
  "modbus_device_count": 1,
  "modbus_tag_count": 3,
  "mqtt_status": "connected",
  "mqtt_broker": "mqtt.eclipseprojects.io",
  "timestamp": 1719123456
}
```

### 2. Otimização Modbus para 3 Tags

**Configuração recomendada:**
```
Device: PLC Principal
- IP: 192.168.1.100
- Port: 502
- Slave ID: 1
- Poll Interval: 60 (segundos) - 1 minuto
- Timeout: 5 (segundos)

Tags:
- Tag 1: Temperatura (Address: 40001, Type: holding, Scale: 0.1)
- Tag 2: Pressão (Address: 40002, Type: holding, Scale: 0.01)
- Tag 3: Umidade (Address: 40003, Type: holding, Scale: 1.0)
```

**Otimização:**
- Batch reading: Ler as 3 tags em uma única conexão Modbus
- Reutilizar conexão TCP entre polls
- Timeout de 5s é suficiente para 3 tags

### 3. Detecção de Tipo de Conexão

```bash
# Detectar interface ativa
detect_connection() {
    # Verificar interface padrão
    DEFAULT_IF=$(ip route show default | awk '/default/ {print $5}')
    
    case "$DEFAULT_IF" in
        eth*|en*)
            echo "cabo"
            ;;
        wlan*|wl*)
            echo "wifi"
            ;;
        ppp*|usb*)
            echo "4g"
            ;;
        *)
            echo "desconhecido"
            ;;
    esac
}
```

### 4. Configuração MQTT Sugerida

```
Broker: mqtt.eclipseprojects.io (ou broker privado)
Port: 1883
Client ID: zlan9809m-$(hostname)
Keep Alive: 60
Topic Prefix: zlan9809m

Tópicos:
- zlan9809m/modbus/PLC Principal/Temperatura
- zlan9809m/modbus/PLC Principal/Pressão
- zlan9809m/modbus/PLC Principal/Umidade
- zlan9809m/system/keepalive
```

### 5. Configuração Tailscale Sugerida

```bash
# Advertise routes para acessar da rede Tailscale
uci set tailscale.@tailscale[0].advertise_routes='192.168.1.0/24'

# Accept DNS para resolver nomes via Tailscale
uci set tailscale.@tailscale[0].accept_dns='1'

# Accept routes para acessar outras redes Tailscale
uci set tailscale.@tailscale[0].accept_routes='1'

# Exit nodes (opcional, para rotear tráfego via Tailscale)
# uci set tailscale.@tailscale[0].exit_node='exit-node-id'

uci commit tailscale
/etc/init.d/tailscale restart
```

## Limitações e Mitigações

### ⚠️ RAM (64MB)

**Problema:**
- Tailscale: 35-45MB
- Modbus daemon: 8-10MB
- MQTT daemon: 8-10MB
- System monitor: 1-2MB
- **Total: ~52-67MB (apertado)**

**Mitigações:**
1. Intervalo de keepalive: 10 minutos (confirmado pelo usuário)
2. Buffer MQTT pequeno (se configurável)
3. Monitoramento para evitar OOM:
   ```bash
   # Adicionar crontab para monitorar RAM
   */5 * * * * free -m | awk '/Mem/ {if ($3 > 55) logger "RAM CRITICAL: " $3 "MB used"}'
   ```
4. Desabilitar LuCI após configuração (libera ~5-10MB):
   ```bash
   /etc/init.d/uhttpd stop
   /etc/init.d/uhttpd disable
   ```
5. Desabilitar serviços não essenciais (cron, rsync, etc.)
6. Polling 1/min é aceitável (processo não crítico)

### ⚠️ Flash (4.5MB)

**Problema:**
- Tailscale: 4.9MB
- Modbus+MQTT: 2.4MB
- **Total: ~7.3MB (excede limite)**

**Mitigações:**
1. Executar cleanup.sh agressivo antes da instalação
2. Remover pacotes não usados após configuração:
   ```bash
   opkg remove luci-theme-*
   opkg remove luci-app-statistics
   opkg remove luci-app-nlbwmon
   ```
3. Considerar expansão do overlay (se firmware suportar):
   ```bash
   # Verificar se há partição extra disponível
   df -h
   ```
4. Usar apenas Tailscale XZ (versão compacta)

### ⚠️ CPU (580MHz)

**Problema:**
- Processador limitado para múltiplos daemons

**Mitigações:**
1. Polling Modbus: 1 minuto (confirmado pelo usuário, processo não crítico)
2. Keepalive: 10 minutos (confirmado pelo usuário)
3. Evitar concorrência intensa
4. Monitorar CPU:
   ```bash
   # Adicionar crontab
   */5 * * * * top -bn1 | grep "Cpu(s)" | logger
   ```

## Plano de Implementação

### Fase 1: Instalação Base
1. Executar cleanup.sh
2. Instalar Tailscale core + LuCI
3. Configurar Tailscale
4. Testar conexão Tailscale

### Fase 2: Modbus + MQTT
1. Instalar libmodbus + mosquitto-client
2. Instalar modbus-daemon + mqtt-daemon
3. Configurar Modbus (3 tags, 30s)
4. Configurar MQTT broker
5. Testar polling e publicação

### Fase 3: System Monitor
1. Criar system-monitor-daemon em Go
2. Empacotar como IPK
3. Configurar intervalo de keepalive (10 minutos)
4. Testar publicação de métricas

### Fase 4: Otimização
1. Desabilitar LuCI após configuração
2. Configurar monitoramento de RAM/CPU
3. Ajustar intervalos se necessário
4. Teste de estabilidade (24-48h)

## Monitoramento e Alertas

### Métricas para Monitorar
1. **RAM**: <55MB usado
2. **CPU**: <10% em idle, <20% durante polling
3. **Flash**: Monitorar espaço livre
4. **Tailscale**: Status conectado
5. **Modbus**: Status conectado, taxa de sucesso >95%
6. **MQTT**: Status conectado, taxa de sucesso >95%

### Alertas Sugeridos
- RAM > 55MB: Alerta crítico
- CPU > 20% contínuo: Alerta de performance
- Modbus/MQTT desconectado > 5min: Alerta de conexão
- Flash < 100MB livre: Alerta de espaço

## Conclusão

**O hardware ZLAN9809M é totalmente viável para este caso de uso específico:**
- ✅ Carga leve (3 tags/1min, processo não crítico)
- ✅ Tráfego de rede mínimo
- ✅ Custo baixo
- ⚠️ RAM apertada mas gerenciável
- ⚠️ Flash requer cleanup prévio

**Recomendações principais:**
1. Criar system-monitor-daemon para keepalive
2. Intervalo de keepalive: 10 minutos (confirmado pelo usuário)
3. Polling Modbus: 1 minuto (confirmado pelo usuário, processo não crítico)
4. Desabilitar LuCI após configuração
5. Monitorar RAM e CPU continuamente
6. Executar cleanup agressivo antes da instalação

**Custo-benefício:** Excelente para o caso de uso descrito.
