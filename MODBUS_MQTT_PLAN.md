# Plano de Implementação - Modbus TCP/IP + MQTT

## Objetivo

Adicionar funcionalidades de teste Modbus TCP/IP e MQTT ao ZLAN9809M, mantendo o Tailscale e todas as funcionalidades atuais.

## Requisitos

### Modbus TCP/IP
- Pooling de dispositivos Modbus TCP/IP
- Leitura de tags/registros
- Configuração persistente (IP, ID, tags, polling time, timeout)
- Interface LuCI para gerenciamento
- Visualização de status e valores lidos

### MQTT
- Conexão com broker online
- Keepalive automático
- Publicação de tags do Modbus
- Configuração persistente (broker URL, port, username, password)
- Interface LuCI para configuração

## Avaliação de Espaço

### Espaço Atual (após Tailscale + Cleanup)
- Overlay: 8-12MB livres
- RAM: 32MB livres

### Estimativa de Espaço Necessário

**Libmodbus:**
- Biblioteca compilada: ~500KB
- Headers: ~100KB
- Total: ~600KB

**Mosquitto (MQTT Client):**
- Binário: ~400KB
- Bibliotecas: ~200KB
- Total: ~600KB

**Daemon Modbus (Go):**
- Binário compilado: ~2-3MB
- Com UPX: ~1MB
- Total: ~1MB

**Daemon MQTT (Go):**
- Binário compilado: ~2-3MB
- Com UPX: ~1MB
- Total: ~1MB

**Interfaces LuCI:**
- Modbus UI: ~50KB
- MQTT UI: ~50KB
- Total: ~100KB

**Total estimado:** ~3.3MB

### Espaço Disponível
- Atual: 8-12MB livres
- Necessário: ~3.3MB
- Restante: 4.7-8.7MB ✅

**Conclusão:** Há espaço suficiente para implementar Modbus + MQTT mantendo Tailscale.

## Arquitetura

### Componentes

1. **libmodbus** (Cross-compilado para MIPS 24Kc)
   - Biblioteca C para comunicação Modbus
   - Funções de leitura/escrita

2. **modbus-daemon** (Go)
   - Daemon de pooling Modbus
   - Lê tags periodicamente
   - Salva em arquivo de estado
   - Integra com MQTT daemon

3. **mqtt-daemon** (Go)
   - Daemon MQTT client
   - Conecta ao broker
   - Publica tags do Modbus
   - Mantém keepalive

4. **LuCI Modbus**
   - Interface para configurar dispositivos
   - Visualização de status
   - Adicionar/remover tags

5. **LuCI MQTT**
   - Interface para configurar broker
   - Status da conexão
   - Visualização de mensagens

### Fluxo de Dados

```
Modbus Device → modbus-daemon → arquivo estado → mqtt-daemon → Broker MQTT
                        ↓
                   LuCI Interface
```

## Estrutura de Diretórios

```
modbus/
├── build-modbus.sh (cross-compilação libmodbus)
├── build-mosquitto.sh (cross-compilação mosquitto)
├── modbus-daemon/ (Go source)
│   ├── main.go
│   ├── modbus.go
│   └── config.go
├── mqtt-daemon/ (Go source)
│   ├── main.go
│   ├── mqtt.go
│   └── config.go
├── files/
│   ├── etc/config/modbus
│   ├── etc/config/mqtt
│   └── etc/init.d/modbus-daemon
├── luci/modbus/ (LuCI interface)
└── luci/mqtt/ (LuCI interface)
```

## Configuração UCI

### Modbus
```
config modbus 'device1'
    option enabled '1'
    option name 'PLC Principal'
    option ip '192.168.1.100'
    option port '502'
    option slave_id '1'
    option poll_interval '5'
    option timeout '3'
    
config tag 'tag1'
    option device 'device1'
    option name 'Temperature'
    option address '40001'
    option type 'holding'
    option scale '0.1'
    option offset '0'
```

### MQTT
```
config mqtt 'client'
    option enabled '1'
    option broker 'mqtt.example.com'
    option port '1883'
    option username 'user'
    option password 'pass'
    option client_id 'zlan9809m'
    option keepalive '60'
    option topic_prefix 'zlan9809m'
```

## Implementação

### Fase 1: Cross-compilação
1. Script para compilar libmodbus para MIPS 24Kc
2. Script para compilar mosquitto para MIPS 24Kc
3. Empacotar como IPK

### Fase 2: Daemons Go
1. Criar modbus-daemon em Go
2. Criar mqtt-daemon em Go
3. Compilar para MIPS 24Kc
4. Empacotar como IPK

### Fase 3: Interfaces LuCI
1. Criar controller Modbus
2. Criar model CBI Modbus
3. Criar view status Modbus
4. Criar controller MQTT
5. Criar model CBI MQTT
6. Criar view status MQTT

### Fase 4: Integração
1. Atualizar auto_install.sh com opção
2. Atualizar cleanup.sh para incluir novos pacotes
3. Atualizar documentação

## Dependências

**Sistema:**
- libmodbus (cross-compilado)
- mosquitto-client (cross-compilado)

**Go:**
- github.com/goburrow/modbus (wrapper Go para libmodbus)
- github.com/eclipse/paho.mqtt.golang (cliente MQTT)

**OpenWrt:**
- Nenhuma dependência adicional (usamos binários estáticos)

## Riscos e Mitigação

**Risco 1: Espaço insuficiente**
- Mitigação: Compilação agressiva, UPX, XZ compressão
- Fallback: Instalação opcional via menu

**Risco 2: Cross-compilação libmodbus**
- Mitigação: Usar toolchain OpenWrt existente
- Fallback: Implementar Modbus puro em Go (sem libmodbus)

**Risco 3: Performance**
- Mitigação: Pooling otimizado, cache de valores
- Fallback: Ajustar intervalo de polling

**Risco 4: Conflito com Tailscale**
- Mitigação: Processos independentes, recursos separados
- Fallback: Monitoramento de uso de CPU

## Cronograma

1. **Avaliação e planejamento** (concluído)
2. **Cross-compilação libmodbus** (1-2 horas)
3. **Cross-compilação mosquitto** (1-2 horas)
4. **Desenvolvimento modbus-daemon** (2-3 horas)
5. **Desenvolvimento mqtt-daemon** (2-3 horas)
6. **Interfaces LuCI** (3-4 horas)
7. **Integração e testes** (2-3 horas)
8. **Documentação** (1 hora)

**Total estimado:** 12-18 horas

## Próximos Passos

1. Criar script de cross-compilação libmodbus
2. Criar script de cross-compilação mosquitto
3. Desenvolver modbus-daemon em Go
4. Desenvolver mqtt-daemon em Go
5. Criar interfaces LuCI
6. Integrar no auto_install.sh
7. Testar completamente
8. Atualizar documentação
