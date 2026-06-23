package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

// Config representa a configuração do daemon MQTT
type Config struct {
	Broker      string `json:"broker"`
	Port        int    `json:"port"`
	Username    string `json:"username"`
	Password    string `json:"password"`
	ClientID    string `json:"client_id"`
	KeepAlive   int    `json:"keepalive"`
	TopicPrefix string `json:"topic_prefix"`
}

// ModbusState representa o estado do Modbus daemon
type ModbusState struct {
	Devices map[string]DeviceState `json:"devices"`
}

// DeviceState representa o estado de um dispositivo
type DeviceState struct {
	Values  []TagValue `json:"values"`
	Status  string     `json:"status"`
	LastRead time.Time  `json:"last_read"`
}

// TagValue representa o valor de uma tag
type TagValue struct {
	Name      string  `json:"name"`
	Value     float64 `json:"value"`
	Timestamp int64   `json:"timestamp"`
	Quality   string  `json:"quality"`
}

var (
	config      Config
	mqttClient  mqtt.Client
	stateFile   = "/var/lib/modbus-daemon/state.json"
)

func main() {
	log.Println("==========================================")
	log.Println("MQTT Daemon - ZLAN9809M")
	log.Println("==========================================")

	// Carregar configuração
	if err := loadConfig(); err != nil {
		log.Fatalf("Erro ao carregar configuração: %v", err)
	}

	// Conectar ao broker MQTT
	if err := connectMQTT(); err != nil {
		log.Fatalf("Erro ao conectar ao broker MQTT: %v", err)
	}

	// Iniciar publicação de tags
	go publishTags()

	// Aguardar sinal de encerramento
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("Encerrando daemon...")
	mqttClient.Disconnect(250)
	log.Println("Daemon encerrado.")
}

func loadConfig() error {
	// Ler configuração de UCI
	// Por enquanto, usar arquivo JSON
	configFile := "/etc/mqtt-daemon/config.json"
	if _, err := os.Stat(configFile); os.IsNotExist(err) {
		// Criar configuração padrão
		config = Config{
			Broker:      "mqtt.eclipseprojects.io",
			Port:        1883,
			Username:    "",
			Password:    "",
			ClientID:    "zlan9809m",
			KeepAlive:   60,
			TopicPrefix: "zlan9809m",
		}
		return nil
	}

	data, err := os.ReadFile(configFile)
	if err != nil {
		return err
	}

	return json.Unmarshal(data, &config)
}

func connectMQTT() error {
	opts := mqtt.NewClientOptions()
	opts.AddBroker(fmt.Sprintf("tcp://%s:%d", config.Broker, config.Port))
	opts.SetClientID(config.ClientID)
	opts.SetKeepAlive(time.Duration(config.KeepAlive) * time.Second)
	
	if config.Username != "" {
		opts.SetUsername(config.Username)
	}
	if config.Password != "" {
		opts.SetPassword(config.Password)
	}

	opts.SetAutoReconnect(true)
	opts.SetOnConnectHandler(func(client mqtt.Client) {
		log.Println("Conectado ao broker MQTT")
	})

	opts.SetConnectionLostHandler(func(client mqtt.Client, err error) {
		log.Printf("Conexão perdida: %v", err)
	})

	mqttClient = mqtt.NewClient(opts)
	if token := mqttClient.Connect(); token.Wait() && token.Error() != nil {
		return token.Error()
	}

	return nil
}

func publishTags() {
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		if err := readAndPublish(); err != nil {
			log.Printf("Erro ao publicar tags: %v", err)
		}
	}
}

func readAndPublish() error {
	// Ler estado do Modbus daemon
	data, err := os.ReadFile(stateFile)
	if err != nil {
		return err
	}

	var modbusState ModbusState
	if err := json.Unmarshal(data, &modbusState); err != nil {
		return err
	}

	// Publicar cada tag
	for deviceName, deviceState := range modbusState.Devices {
		for _, tag := range deviceState.Values {
			if tag.Quality != "good" {
				continue
			}

			topic := fmt.Sprintf("%s/%s/%s", config.TopicPrefix, deviceName, tag.Name)
			payload := map[string]interface{}{
				"value":     tag.Value,
				"timestamp": tag.Timestamp,
				"quality":   tag.Quality,
			}

			payloadBytes, err := json.Marshal(payload)
			if err != nil {
				log.Printf("Erro ao serializar payload para %s: %v", topic, err)
				continue
			}

			token := mqttClient.Publish(topic, 0, false, payloadBytes)
			token.Wait()
			if token.Error() != nil {
				log.Printf("Erro ao publicar %s: %v", topic, token.Error())
			}
		}
	}

	return nil
}
