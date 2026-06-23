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
┌─────────────────────────────────────────────────────────────────────┐
│ LuCI → Services → Modbus TCP                                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ╔══════════════════════════════════════════════════════════════════╗ │
│  ║ Modbus TCP                                                       ║ │
│  ║ Configure Modbus TCP devices for polling and data collection.    ║ │
│  ╚══════════════════════════════════════════════════════════════════╝ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ Modbus Devices                                                  │ │
│  │                                                               │ │
│  │ ┌─────────────────────────────────────────────────────────┐  │ │
│  │ │ Device Configuration                                     │  │ │
│  │ │                                                         │  │ │
│  │ │ Enable:     [✓]                                        │  │ │
│  │ │ Name:       [PLC Principal                  ]           │  │ │
│  │ │ IP:         [192.168.1.100                 ]           │  │ │
│  │ │ Port:       [502                           ]           │  │ │
│  │ │ Slave ID:   [1                             ]           │  │ │
│  │ │ Poll Int:   [60 (seconds)                 ]           │  │ │
│  │ │ Timeout:    [5 (seconds)                  ]           │  │ │
│  │ │                                                         │  │ │
│  │ │ [Save] [Reset]                                            │  │ │
│  │ └─────────────────────────────────────────────────────────┘  │ │
│  │                                                               │ │
│  │ ┌─────────────────────────────────────────────────────────┐  │ │
│  │ │ Device List                                              │  │ │
│  │ │                                                         │  │ │
│  │ │ ✓ PLC Principal                                         │  │ │
│  │ │   IP: 192.168.1.100:502  Slave: 1  Poll: 60s           │  │ │
│  │ │   [Edit] [Delete]                                        │  │ │
│  │ │                                                         │  │ │
│  │ │ [+ Add Device]                                           │  │ │
│  │ └─────────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ Modbus Tags                                                    │ │
│  │                                                               │ │
│  │ ┌─────────────────────────────────────────────────────────┐  │ │
│  │ │ Tag Configuration                                        │  │ │
│  │ │                                                         │  │ │
│  │ │ Device:     [PLC Principal                ▼]           │  │ │
│  │ │ Name:       [Temperatura                   ]           │  │ │
│  │ │ Address:    [40001                         ]           │  │ │
│  │ │ Type:       [Holding Register              ▼]           │  │ │
│  │ │ Scale:      [0.1                           ]           │  │ │
│  │ │ Offset:     [0                             ]           │  │ │
│  │ │                                                         │  │ │
│  │ │ [Save] [Reset]                                            │  │ │
│  │ └─────────────────────────────────────────────────────────┘  │ │
│  │                                                               │ │
│  │ ┌─────────────────────────────────────────────────────────┐  │ │
│  │ │ Tag List                                                 │  │ │
│  │ │                                                         │  │ │
│  │ │ • Temperatura (PLC Principal)                           │  │ │
│  │ │   Addr: 40001  Type: Holding  Scale: 0.1  Offset: 0    │  │ │
│  │ │   [Edit] [Delete]                                        │  │ │
│  │ │                                                         │  │ │
│  │ │ • Pressão (PLC Principal)                                │  │ │
│  │ │   Addr: 40002  Type: Holding  Scale: 0.01 Offset: 0    │  │ │
│  │ │   [Edit] [Delete]                                        │  │ │
│  │ │                                                         │  │ │
│  │ │ • Umidade (PLC Principal)                                │  │ │
│  │ │   Addr: 40003  Type: Holding  Scale: 1.0  Offset: 0    │  │ │
│  │ │   [Edit] [Delete]                                        │  │ │
│  │ │                                                         │  │ │
│  │ │ [+ Add Tag]                                              │  │ │
│  │ └─────────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ Status                                                        │ │
│  │                                                               │ │
│  │ Device           IP:Port         Slave    Poll    Status      │ │
│  │ ───────────────────────────────────────────────────────────── │ │
│  │ PLC Principal    192.168.1.100:502  1       60s     🟢 Connected│ │
│  │                                                               │ │
│  │ Last Poll: 2 seconds ago                                    │ │
│  │ Tags Read: 3/3 Success                                      │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│                                                [Save] [Save & Apply] │
└─────────────────────────────────────────────────────────────────────┘
```

**Nota:** Após testar no hardware real, você pode adicionar screenshots reais aqui.
Para tirar screenshots do LuCI:
1. Acesse o roteador via SSH
2. Execute: `opkg install luci-app-screenshot` (se disponível)
3. Ou use ferramenta de screenshot do navegador ao acessar LuCI

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
┌─────────────────────────────────────────────────────────────────────┐
│ LuCI → Services → MQTT Client                                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ╔══════════════════════════════════════════════════════════════════╗ │
│  ║ MQTT Client                                                      ║ │
│  ║ Configure MQTT client to publish Modbus tags to an MQTT broker.   ║ │
│  ╚══════════════════════════════════════════════════════════════════╝ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ MQTT Configuration                                              │ │
│  │                                                               │ │
│  │ ┌─────────────────────────────────────────────────────────┐  │ │
│  │ │ Connection Settings                                     │  │ │
│  │ │                                                         │  │ │
│  │ │ Enable:        [✓]                                     │  │ │
│  │ │ Broker URL:    [mqtt.eclipseprojects.io        ]       │  │ │
│  │ │ Port:          [1883                           ]       │  │ │
│  │ │ Username:      [                                ]       │  │ │
│  │ │ Password:      [•••••••••••••••                ]       │  │ │
│  │ │ Client ID:     [zlan9809m                       ]       │  │ │
│  │ │ Keep Alive:    [60 (seconds)                   ]       │  │ │
│  │ │ Topic Prefix:  [zlan9809m                       ]       │  │ │
│  │ │                                                         │  │ │
│  │ │ Broker URL: Hostname ou IP do broker MQTT              │  │ │
│  │ │ Port: Porta TCP (padrão: 1883, 8883 para TLS)          │  │ │
│  │ │ Username/Password: Autenticação (opcional)            │  │ │
│  │ │ Client ID: Identificador único deste cliente           │  │ │
│  │ │ Keep Alive: Intervalo de keep-alive em segundos       │  │ │
│  │ │ Topic Prefix: Prefixo para tópicos MQTT               │  │ │
│  │ │                                                         │  │ │
│  │ │ [Save] [Reset]                                            │  │ │
│  │ └─────────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ Status                                                        │ │
│  │                                                               │ │
│  │ ┌─────────────────────────────────────────────────────────┐  │ │
│  │ │ Connection Status                                      │  │ │
│  │ │                                                         │  │ │
│  │ │ Status:        🟢 Connected                            │  │ │
│  │ │ Broker:        mqtt.eclipseprojects.io                  │  │ │
│  │ │ Port:          1883                                    │  │ │
│  │ │ Client ID:     zlan9809m                               │  │ │
│  │ │ Connected:     2 minutes ago                           │  │ │
│  │ │ Enabled:       Yes                                     │  │ │
│  │ │                                                         │  │ │
│  │ │ Messages Published: 156                                 │  │ │
│  │ │ Messages Failed: 0                                     │  │ │
│  │ └─────────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ Topic Preview                                                 │ │
│  │                                                               │ │
│  │ Active Topics:                                                │ │
│  │ • zlan9809m/PLC Principal/Temperatura                        │ │
│  │ • zlan9809m/PLC Principal/Pressão                            │ │
│  │ • zlan9809m/PLC Principal/Umidade                            │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│                                                [Save] [Save & Apply] │
└─────────────────────────────────────────────────────────────────────┘
```

**Nota:** Após testar no hardware real, você pode adicionar screenshots reais aqui.

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

## Screenshots Reais (Para Adicionar Após Teste)

Após testar no hardware real, adicione screenshots das telas de configuração aqui.

### Tela de Configuração Modbus
```
[SCREENSHOT: LuCI → Services → Modbus TCP]
- Mostrar formulário de configuração de dispositivo
- Mostrar lista de tags configuradas
- Mostrar status de conexão
```

### Tela de Configuração MQTT
```
[SCREENSHOT: LuCI → Services → MQTT Client]
- Mostrar formulário de configuração de broker
- Mostrar status de conexão
- Mostrar tópicos ativos
```

### Tela de Status do Sistema
```
[SCREENSHOT: LuCI → Status → Overview]
- Mostrar uso de RAM/CPU
- Mostrar status dos serviços
- Mostrar conexões de rede
```

### Como Adicionar Screenshots

**Método 1: Screenshot do Navegador**
1. Acesse LuCI no navegador
2. Use ferramenta de screenshot (Snipping Tool, etc.)
3. Salve como PNG/JPG
4. Adicione ao repositório em `docs/screenshots/`
5. Atualize este documento com as imagens

**Método 2: Via SSH (se disponível)**
```bash
# Se o LuCI tiver suporte a screenshot
opkg install luci-app-screenshot
# Acesse LuCI → System → Screenshot
```

**Método 3: Emulação/Virtualização**
Se você tiver acesso ao firmware em emulador, pode capturar screenshots de lá.

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
