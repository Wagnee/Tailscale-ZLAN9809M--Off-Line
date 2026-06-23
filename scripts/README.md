# Scripts de Auto-Update

Este diretório contém scripts para o sistema de auto-update com whitelist.

## Arquivos

### hello-world-mqtt.sh
Script de exemplo que envia mensagem "Hello World" via MQTT no tópico `/Hello/World`.

**Configurações:**
- Broker: mqtt.eclipseprojects.io
- Porta: 1883
- Tópico: /Hello/World
- Mensagem: Hello World

### auto-update-whitelist.conf
Whitelist de scripts permitidos para execução automática.

**Formato:**
```
nome_script.sh:descrição
```

**Exemplo:**
```
hello-world-mqtt.sh:Envia mensagem Hello World via MQTT
```

### auto-update-daemon.sh
Daemon que verifica scripts no repositório a cada 10 minutos e executa apenas scripts que estão na whitelist.

**Configurações:**
- Repositório: https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main/scripts
- Intervalo: 600 segundos (10 minutos)
- Whitelist: /etc/auto-update-whitelist.conf
- Log: /var/log/auto-update-daemon.log

### install-auto-update-daemon.sh
Script de instalação do daemon de auto-update.

**Instalação:**
```bash
cd scripts
bash install-auto-update-daemon.sh
```

## Como Funciona

1. Daemon verifica scripts no repositório a cada 10 minutos
2. Para cada script encontrado:
   - Verifica se está na whitelist
   - Se SIM: baixa e executa
   - Se NÃO: recusa e loga
3. Scripts já executados (mesmo hash) são pulados
4. Logs são salvos em /var/log/auto-update-daemon.log

## Adicionando Novos Scripts

1. Criar script novo neste diretório
2. Adicionar à whitelist em auto-update-whitelist.conf
3. Commit e push para o repositório
4. Daemon baixará e executará automaticamente

## Exemplo de Script

```bash
#!/bin/bash
# meu-script.sh - Meu script personalizado

echo "Executando meu script..."
# Seu código aqui

exit 0
```

Adicionar à whitelist:
```
meu-script.sh:Meu script personalizado
```

## Segurança

- **Whitelist**: Apenas scripts na whitelist são executados
- **Hash**: Scripts com mesmo hash não são re-executados
- **Timeout**: Scripts têm timeout de 5 minutos
- **Log**: Todas as execuções são logadas

## Monitoramento

**Verificar status:**
```bash
/etc/init.d/auto-update status
```

**Verificar logs:**
```bash
tail -f /var/log/auto-update-daemon.log
```

**Verificar scripts executados:**
```bash
ls -la /var/lib/auto-update-executed/
```

**Verificar whitelist:**
```bash
cat /etc/auto-update-whitelist.conf
```

## Parar/Iniciar Daemon

**Iniciar:**
```bash
/etc/init.d/auto-update start
```

**Parar:**
```bash
/etc/init.d/auto-update stop
```

**Reiniciar:**
```bash
/etc/init.d/auto-update restart
```

**Desabilitar:**
```bash
/etc/init.d/auto-update disable
```
