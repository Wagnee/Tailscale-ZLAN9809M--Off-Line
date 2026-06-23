#!/bin/bash
# hello-world-mqtt.sh - Script de exemplo para auto-update
# Envia mensagem "Hello World" via MQTT

# Configurações MQTT
BROKER="mqtt.eclipseprojects.io"
PORT="1883"
TOPIC="/Hello/World"
MESSAGE="Hello World"
CLIENT_ID="zlan9809m-hello-world"

echo "[$(date)] Enviando mensagem MQTT: $MESSAGE para $TOPIC"

# Enviar mensagem via mosquitto_pub
if command -v mosquitto_pub >/dev/null 2>&1; then
    mosquitto_pub -h "$BROKER" -p "$PORT" -t "$TOPIC" -m "$MESSAGE" -i "$CLIENT_ID"
    
    if [ $? -eq 0 ]; then
        echo "[$(date)] Mensagem enviada com sucesso!"
        exit 0
    else
        echo "[$(date)] ERRO: Falha ao enviar mensagem MQTT"
        exit 1
    fi
else
    echo "[$(date)] ERRO: mosquitto_pub não encontrado"
    exit 1
fi
