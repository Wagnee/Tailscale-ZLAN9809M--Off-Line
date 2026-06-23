# Guia Visual - Modbus TCP + MQTT

## Visão Geral

Este guia mostra como usar as interfaces LuCI para configurar Modbus TCP e MQTT no ZLAN9809M.

## Menu LuCI - Modbus

### Acessando o Menu Modbus

1. Acesse a interface LuCI do roteador:
   ```
   http://router-ip/cgi-bin/luci
   ```

2. Navegue para:
   ```
   Services → Modbus TCP
   ```

### Estrutura do Menu Modbus

```
┌─────────────────────────────────────────────────────────┐
│ LuCI → Services → Modbus TCP                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Modbus TCP                                             │
│  Configure Modbus TCP devices for polling and          │
│  data collection.                                      │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ Modbus Devices                                    │ │
│  │                                                   │ │
│  │ [✓] Enable  [Name] [IP] [Port] [Slave ID]       │ │
│  │                                                   │ │
│  │ Device1: PLC Principal                            │ │
│  │   Enabled: ✓                                      │ │
│  │   IP: 192.168.1.100                              │ │
│  │   Port: 502                                      │ │
│  │   Slave ID: 1                                    │ │
│  │   Poll Interval: 5s                              │ │
│  │   Timeout: 3s                                    │ │
│  │   [Edit] [Delete]                                │ │
│  │                                                   │ │
│  │ [+ Add Device]                                    │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ Modbus Tags                                       │ │
│  │                                                   │ │
│  │ [Device] [Name] [Address] [Type] [Scale] [Offset]│ │
│  │                                                   │ │
│  │ Tag1: Temperatura                                 │ │
│  │   Device: Device1                                 │ │
│  │   Address: 40001                                  │ │
│  │   Type: Holding Register                         │ │
│  │   Scale: 0.1                                      │ │
│  │   Offset: 0                                       │ │
│  │   [Edit] [Delete]                                │ │
│  │                                                   │ │
│  │ [+ Add Tag]                                      │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ Status                                            │ │
│  │                                                   │ │
│  │ Device         IP:Port    Slave ID    Status     │ │
│  │ ────────────────────────────────────────────────  │ │
│  │ PLC Principal  192.168.1.100:502  1    Connected │ │
│  │                                                   │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│                                    [Save] [Save & Apply]│
└─────────────────────────────────────────────────────────┘
```

### Adicionando um Dispositivo Modbus

1. Clique em "[+ Add Device]"
2. Preencha os campos:
   - **Enable**: Marque para ativar o polling
   - **Name**: Nome do dispositivo (ex: "PLC Principal")
   - **IP**: Endereço IP do dispositivo Modbus (ex: "192.168.1.100")
   - **Port**: Porta TCP (padrão: 502)
   - **Slave ID**: ID do escravo Modbus (padrão: 1)
   - **Poll Interval**: Intervalo de polling em segundos (ex: 5)
   - **Timeout**: Timeout em segundos (ex: 3)

3. Clique em "Save & Apply"

### Adicionando Tags Modbus

1. Clique em "[+ Add Tag]"
2. Preencha os campos:
   - **Device**: Selecione o dispositivo configurado
   - **Name**: Nome da tag (ex: "Temperatura")
   - **Address**: Endereço do registro (ex: 40001 para holding register)
   - **Type**: Tipo de registro:
     - Holding Register (leitura/escrita)
     - Input Register (somente leitura)
     - Coil (bit, leitura/escrita)
     - Discrete Input (bit, somente leitura)
   - **Scale**: Fator de escala (ex: 0.1 para dividir por 10)
   - **Offset**: Valor de offset (ex: 0 para nenhum offset)

3. Clique em "Save & Apply"

### Exemplo de Configuração

#### Dispositivo PLC Principal
- Name: PLC Principal
- IP: 192.168.1.100
- Port: 502
- Slave ID: 1
- Poll Interval: 5s
- Timeout: 3s

#### Tags para Temperatura
- Device: PLC Principal
- Name: Temperatura
- Address: 40001
- Type: Holding Register
- Scale: 0.1
- Offset: 0

**Resultado**: Se o valor lido for 255, o valor final será 25.5 (255 × 0.1 + 0)

## Menu LuCI - MQTT

### Acessando o Menu MQTT

1. Acesse a interface LuCI do roteador:
   ```
   http://router-ip/cgi-bin/luci
   ```

2. Navegue para:
   ```
   Services → MQTT Client
   ```

### Estrutura do Menu MQTT

```
┌─────────────────────────────────────────────────────────┐
│ LuCI → Services → MQTT Client                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  MQTT Client                                            │
│  Configure MQTT client to publish Modbus tags to        │
│  an MQTT broker.                                        │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ MQTT Configuration                                │ │
│  │                                                   │ │
│  │ [✓] Enable                                       │ │
│  │                                                   │ │
│  │ Broker URL: [mqtt.eclipseprojects.io        ]     │ │
│  │ Port:       [1883                             ]   │ │
│  │ Username:   [                                 ]   │ │
│  │ Password:   [•••••••••••••••                  ]   │ │
│  │ Client ID:  [zlan9809m                        ]   │ │
│  │ Keep Alive: [60                               ]   │ │
│  │ Topic Prefix: [zlan9809m                      ]   │ │
│  │                                                   │ │
│  │ Broker URL: Hostname ou IP do broker MQTT       │ │
│  │ Port: Porta TCP (padrão: 1883)                  │ │
│  │ Username/Password: Autenticação (opcional)     │ │
│  │ Client ID: Identificador único deste cliente   │ │
│  │ Keep Alive: Intervalo de keep-alive em segundos │ │
│  │ Topic Prefix: Prefixo para tópicos MQTT         │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ Status                                            │ │
│  │                                                   │ │
│  │ Status:        [🟢 Connected]                     │ │
│  │ Broker:        mqtt.eclipseprojects.io            │ │
│  │ Port:          1883                              │ │
│  │ Enabled:       Yes                               │ │
│  │                                                   │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│                                    [Save] [Save & Apply]│
└─────────────────────────────────────────────────────────┘
```

### Configurando o Broker MQTT

1. Preencha os campos:
   - **Enable**: Marque para ativar o cliente MQTT
   - **Broker URL**: Hostname ou IP do broker MQTT
     - Exemplo público: `mqtt.eclipseprojects.io`
     - Exemplo privado: `192.168.1.200`
   - **Port**: Porta TCP (padrão: 1883, ou 8883 para TLS)
   - **Username**: Usuário para autenticação (opcional)
   - **Password**: Senha para autenticação (opcional)
   - **Client ID**: Identificador único (ex: "zlan9809m")
   - **Keep Alive**: Intervalo em segundos (padrão: 60)
   - **Topic Prefix**: Prefixo para tópicos (ex: "zlan9809m")

2. Clique em "Save & Apply"

### Exemplo de Configuração

#### Broker Eclipse IoT (Público)
- Broker URL: mqtt.eclipseprojects.io
- Port: 1883
- Username: (vazio)
- Password: (vazio)
- Client ID: zlan9809m
- Keep Alive: 60
- Topic Prefix: zlan9809m

#### Broker Privado
- Broker URL: 192.168.1.200
- Port: 1883
- Username: admin
- Password: secret123
- Client ID: zlan9809m
- Keep Alive: 60
- Topic Prefix: factory/floor1

## Estrutura de Tópicos MQTT

As tags Modbus são publicadas automaticamente pelo mqtt-daemon no seguinte formato:

```
{topic_prefix}/{device_name}/{tag_name}
```

### Exemplo

Configuração:
- Topic Prefix: zlan9809m
- Device Name: PLC Principal
- Tag Name: Temperatura

Tópico resultante:
```
zlan9809m/PLC Principal/Temperatura
```

### Payload MQTT

O payload é um JSON com o seguinte formato:

```json
{
  "value": 25.5,
  "timestamp": 1719123456,
  "quality": "good"
}
```

**Campos:**
- `value`: Valor da tag (após scale e offset)
- `timestamp`: Timestamp Unix em segundos
- `quality`: "good" ou "bad" (indica se a leitura foi bem-sucedida)

## Fluxo de Dados Completo

```
┌──────────────┐
│ Dispositivo  │
│   Modbus     │
│  192.168.1.100│
└──────┬───────┘
       │ TCP Modbus
       │
┌──────▼───────┐
│ modbus-daemon│ (polling a cada 5s)
└──────┬───────┘
       │ JSON state
       │ /var/lib/modbus-daemon/state.json
       │
┌──────▼───────┐
│ mqtt-daemon  │ (lê e publica a cada 5s)
└──────┬───────┘
       │ MQTT Publish
       │
┌──────▼───────┐
│   Broker     │
│    MQTT      │
│ mqtt.eclipse │
│ projects.io  │
└──────────────┘
```

## Testando a Integração

### 1. Verificar Status do Modbus

No LuCI:
- Acesse Services → Modbus TCP
- Verifique se o status mostra "Connected"

Via CLI:
```bash
/etc/init.d/modbus-daemon status
cat /var/lib/modbus-daemon/state.json
```

### 2. Verificar Status do MQTT

No LuCI:
- Acesse Services → MQTT Client
- Verifique se o status mostra "Connected"

Via CLI:
```bash
/etc/init.d/mqtt-daemon status
```

### 3. Verificar Publicação MQTT

Use um cliente MQTT (ex: MQTT Explorer, mosquitto_sub):

```bash
mosquitto_sub -h mqtt.eclipseprojects.io -t "zlan9809m/#" -v
```

Você deve ver mensagens como:
```
zlan9809m/PLC Principal/Temperatura {"value":25.5,"timestamp":1719123456,"quality":"good"}
```

## Solução de Problemas

### Modbus não conecta
- Verifique se o IP do dispositivo está correto
- Verifique se o dispositivo Modbus está acessível (ping)
- Verifique se a porta está correta (padrão: 502)
- Aumente o timeout se necessário

### MQTT não conecta
- Verifique se o broker URL está correto
- Verifique se a porta está correta (1883 para TCP, 8883 para TLS)
- Verifique credenciais se o broker requer autenticação
- Verifique se há firewall bloqueando a conexão

### Tags não são publicadas
- Verifique se modbus-daemon está rodando e conectado
- Verifique se mqtt-daemon está rodando e conectado
- Verifique se as tags estão configuradas corretamente
- Verifique o arquivo de estado: `/var/lib/modbus-daemon/state.json`

### Alto uso de CPU
- Aumente o intervalo de polling (Poll Interval)
- Reduza o número de tags
- Verifique se há muitos dispositivos configurados

### Alto uso de RAM
- Reduza o número de tags
- Reduza o buffer do MQTT (se configurável)
- Considere usar apenas Tailscale sem Modbus+MQTT em dispositivos com 64MB RAM

## Scripts de CLI Alternativos

### Configurar Modbus via CLI

```bash
# Adicionar dispositivo
uci add modbus device
uci set modbus.@device[-1].enabled='1'
uci set modbus.@device[-1].name='PLC Principal'
uci set modbus.@device[-1].ip='192.168.1.100'
uci set modbus.@device[-1].port='502'
uci set modbus.@device[-1].slave_id='1'
uci set modbus.@device[-1].poll_interval='5'
uci set modbus.@device[-1].timeout='3'
uci commit modbus

# Adicionar tag
uci add modbus tag
uci set modbus.@tag[-1].device='device1'
uci set modbus.@tag[-1].name='Temperatura'
uci set modbus.@tag[-1].address='40001'
uci set modbus.@tag[-1].type='holding'
uci set modbus.@tag[-1].scale='0.1'
uci set modbus.@tag[-1].offset='0'
uci commit modbus

# Reiniciar daemon
/etc/init.d/modbus-daemon restart
```

### Configurar MQTT via CLI

```bash
# Configurar broker
uci set mqtt.client.enabled='1'
uci set mqtt.client.broker='mqtt.eclipseprojects.io'
uci set mqtt.client.port='1883'
uci set mqtt.client.username=''
uci set mqtt.client.password=''
uci set mqtt.client.client_id='zlan9809m'
uci set mqtt.client.keepalive='60'
uci set mqtt.client.topic_prefix='zlan9809m'
uci commit mqtt

# Reiniciar daemon
/etc/init.d/mqtt-daemon restart
```
