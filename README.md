# Tailscale para ZLAN9809M (Versão Compacta)

Este projeto fornece uma versão otimizada do Tailscale para o roteador ZLAN9809M, respeitando o limite de 4MB de espaço disponível para instalação.

## Especificações do Dispositivo

- **Processador**: MediaTek MT7628NN (MIPS 24Kc, little-endian)
- **Flash**: 16MB total (4MB disponível para instalação)
- **RAM**: 64MB/128MB
- **Arquitetura**: mipsel_24kc

## Funcionalidades Incluídas

- Conexão à tailnet especificada
- Advertise Routes da subrede DHCP configurada no roteador
- Persistência de configuração na memória do dispositivo
- Interface de configuração via LuCI (OpenWrt Web UI)

## Funcionalidades Omitidas (para reduzir tamanho)

- AWS integration
- BIRD routing daemon
- Shell completion
- Kubernetes integration
- System tray
- Taildrop
- TAP device support
- TPM support
- Relay server (DERP)
- Packet capture
- System policy
- Debug event bus
- Web client

## Estrutura do Projeto

```
.
├── build.sh              # Script de compilação
├── install.sh            # Script de instalação
├── files/
│   ├── etc/
│   │   ├── config/
│   │   │   └── tailscale # Configuração UCI
│   │   ├── init.d/
│   │   │   └── tailscale # Script de init
│   │   └── hotplug.d/
│   │       └── iface/
│   │           └── 99-tailscale # Hotplug para DHCP
│   └── uci-defaults/
│       └── tailscale     # Configuração padrão
└── luci/
    └── tailscale/
        └── luasrc/
            └── controller/
                └── admin/
                    └── tailscale.lua
```

## Compilação

### Preparação (Windows)

Se estiver no Windows, abra o WSL2 ou Git Bash e execute:

```bash
./prepare.sh
```

Ou manualmente:

```bash
chmod +x build.sh install.sh package.sh
chmod +x files/etc/init.d/tailscale
chmod +x files/etc/hotplug.d/iface/99-tailscale
chmod +x files/etc/uci-defaults/99-tailscale
```

### Compilação

Execute o script de compilação:

```bash
./build.sh
```

Isso irá:
1. Baixar o código fonte do Tailscale
2. Compilar para arquitetura mipsel_24kc com otimizações
3. Aplicar compressão UPX
4. Gerar o binário `tailscaled`

## Instalação

Execute o script de instalação no roteador:

```bash
./install.sh
```

Ou copie manualmente os arquivos para o roteador e execute:

```bash
opkg install kmod-tun ca-bundle
chmod +x /usr/sbin/tailscaled
/etc/init.d/tailscale enable
/etc/init.d/tailscale start
```

## Configuração

### Via LuCI

Acesse `http://router-ip/cgi-bin/luci/admin/network/tailscale` para configurar:
- Tailnet URL
- Auth Key
- Advertise Routes (DHCP range)
- Outras opções

### Via CLI

```bash
# Configurar via UCI
uci set tailscale.@tailscale[0].enabled='1'
uci set tailscale.@tailscale[0].auth_key='tskey-auth-xxx'
uci set tailscale.@tailscale[0].advertise_routes='192.168.1.0/24'
uci commit tailscale

# Iniciar serviço
/etc/init.d/tailscale restart
```

## Licença

MIT License - Ver arquivo LICENSE para detalhes.
