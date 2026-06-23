package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/goburrow/modbus"
)

// Config representa a configuração do daemon
type Config struct {
	Devices []DeviceConfig `json:"devices"`
}

// DeviceConfig representa a configuração de um dispositivo Modbus
type DeviceConfig struct {
	Name         string        `json:"name"`
	IP           string        `json:"ip"`
	Port         int           `json:"port"`
	SlaveID      byte          `json:"slave_id"`
	PollInterval time.Duration `json:"poll_interval"`
	Timeout      time.Duration `json:"timeout"`
	Tags         []TagConfig   `json:"tags"`
}

// TagConfig representa a configuração de uma tag
type TagConfig struct {
	Name   string  `json:"name"`
	Type   string  `json:"type"` // "coil", "discrete", "holding", "input"
	Addr   uint16  `json:"address"`
	Scale  float64 `json:"scale"`
	Offset float64 `json:"offset"`
}

// TagValue representa o valor lido de uma tag
type TagValue struct {
	Name      string  `json:"name"`
	Value     float64 `json:"value"`
	Timestamp int64   `json:"timestamp"`
	Quality   string  `json:"quality"`
}

// DeviceState representa o estado de um dispositivo
type DeviceState struct {
	Config  DeviceConfig `json:"config"`
	Values  []TagValue   `json:"values"`
	Status  string       `json:"status"`
	LastRead time.Time    `json:"last_read"`
}

var (
	config      Config
	deviceStates map[string]*DeviceState
	stateFile   = "/var/lib/modbus-daemon/state.json"
)

func main() {
	log.Println("==========================================")
	log.Println("Modbus Daemon - ZLAN9809M")
	log.Println("==========================================")

	// Carregar configuração
	if err := loadConfig(); err != nil {
		log.Fatalf("Erro ao carregar configuração: %v", err)
	}

	// Inicializar estados
	deviceStates = make(map[string]*DeviceState)
	for _, dev := range config.Devices {
		deviceStates[dev.Name] = &DeviceState{
			Config: dev,
			Values: make([]TagValue, 0),
			Status: "disconnected",
		}
	}

	// Carregar estado anterior
	loadState()

	// Iniciar polling
	log.Println("Iniciando polling...")
	for _, dev := range config.Devices {
		go pollDevice(dev.Name)
	}

	// Salvar estado periodicamente
	go saveStatePeriodically()

	// Aguardar sinal de encerramento
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("Encerrando daemon...")
	saveState()
	log.Println("Daemon encerrado.")
}

func loadConfig() error {
	// Ler configuração de UCI
	// Por enquanto, usar arquivo JSON
	configFile := "/etc/modbus-daemon/config.json"
	if _, err := os.Stat(configFile); os.IsNotExist(err) {
		// Criar configuração padrão
		config = Config{
			Devices: []DeviceConfig{},
		}
		return nil
	}

	data, err := os.ReadFile(configFile)
	if err != nil {
		return err
	}

	return json.Unmarshal(data, &config)
}

func pollDevice(deviceName string) {
	state := deviceStates[deviceName]
	config := state.Config

	ticker := time.NewTicker(config.PollInterval)
	defer ticker.Stop()

	for range ticker.C {
		if err := readDevice(state); err != nil {
			log.Printf("Erro ao ler dispositivo %s: %v", deviceName, err)
			state.Status = "error"
		} else {
			state.Status = "connected"
			state.LastRead = time.Now()
		}
	}
}

func readDevice(state *DeviceState) error {
	config := state.Config

	// Criar cliente Modbus TCP
	handler := modbus.NewTCPClientHandler(fmt.Sprintf("%s:%d", config.IP, config.Port))
	handler.Timeout = config.Timeout
	handler.SlaveId = config.SlaveID
	defer handler.Close()

	if err := handler.Connect(); err != nil {
		return fmt.Errorf("erro ao conectar: %w", err)
	}

	client := modbus.NewClient(handler)
	state.Values = make([]TagValue, 0, len(config.Tags))

	for _, tag := range config.Tags {
		value, err := readTag(client, tag)
		if err != nil {
			log.Printf("Erro ao ler tag %s: %v", tag.Name, err)
			state.Values = append(state.Values, TagValue{
				Name:      tag.Name,
				Value:     0,
				Timestamp: time.Now().Unix(),
				Quality:   "bad",
			})
			continue
		}

		// Aplicar scale e offset
		scaledValue := float64(value)*tag.Scale + tag.Offset
		state.Values = append(state.Values, TagValue{
			Name:      tag.Name,
			Value:     scaledValue,
			Timestamp: time.Now().Unix(),
			Quality:   "good",
		})
	}

	return nil
}

func readTag(client *modbus.Client, tag TagConfig) (uint16, error) {
	switch tag.Type {
	case "coil":
		results, err := client.ReadCoils(tag.Addr, 1)
		if err != nil {
			return 0, err
		}
		if len(results) > 0 && results[0] {
			return 1, nil
		}
		return 0, nil
	case "discrete":
		results, err := client.ReadDiscreteInputs(tag.Addr, 1)
		if err != nil {
			return 0, err
		}
		if len(results) > 0 && results[0] {
			return 1, nil
		}
		return 0, nil
	case "holding":
		results, err := client.ReadHoldingRegisters(tag.Addr, 1)
		if err != nil {
			return 0, err
		}
		if len(results) > 0 {
			return results[0], nil
		}
		return 0, nil
	case "input":
		results, err := client.ReadInputRegisters(tag.Addr, 1)
		if err != nil {
			return 0, err
		}
		if len(results) > 0 {
			return results[0], nil
		}
		return 0, nil
	default:
		return 0, fmt.Errorf("tipo de tag desconhecido: %s", tag.Type)
	}
}

func saveState() error {
	data, err := json.Marshal(deviceStates)
	if err != nil {
		return err
	}

	// Criar diretório se não existir
	if err := os.MkdirAll("/var/lib/modbus-daemon", 0755); err != nil {
		return err
	}

	return os.WriteFile(stateFile, data, 0644)
}

func loadState() error {
	data, err := os.ReadFile(stateFile)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}

	return json.Unmarshal(data, &deviceStates)
}

func saveStatePeriodically() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		if err := saveState(); err != nil {
			log.Printf("Erro ao salvar estado: %v", err)
		}
	}
}
