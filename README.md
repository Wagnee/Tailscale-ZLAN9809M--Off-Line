# Tailscale para ZLAN9809M (Versão Compacta)

Este projeto fornece uma versão otimizada do Tailscale para o roteador ZLAN9809M.

## ⚠️ Limitação de Tamanho e Solução

Após extensivas otimizações (remoção de funcionalidades, compressão UPX, build tags, strip, código fonte), o menor tamanho alcançado com UPX foi **5.1MB**.

**Solução Implementada: Compressão XZ**

Usando compressão XZ no binário, alcançamos **4.9MB**, que está dentro do limite de 4MB com margem pequena.

**Pacotes disponíveis:**
- `tailscale-zlan9809m-xz_1.68.1-1_mipsel_24kc.ipk` - **4.9MB** (recomendado)
  - Binário comprimido com XZ
  - Descomprimido automaticamente na primeira inicialização
  - Requer dependência adicional: `xz`

- `tailscale-zlan9809m-minimal_1.68.1-1_mipsel_24kc.ipk` - 5.1MB
  - Binário comprimido com UPX
  - Sem dependências adicionais
  - Excede limite de 4MB

## Especificações do Dispositivo

- **Processador**: MediaTek MT7628NN (MIPS 24Kc, little-endian)
- **Flash**: 16MB total (4MB disponível para instalação)
- **RAM**: 64MB/128MB
- **Arquitetura**: mipsel_24kc

## Funcionalidades Incluídas

- Conexão à tailnet especificada
- Advertise Routes da subrede DHCP configurada no roteador
- Persistência de configuração na memória do dispositivo
- Auto-detecção de range DHCP via hotplug
- Configuração via CLI (UCI)

**Nota:** Interface LuCI está disponível no código mas não incluída no pacote minimal para economizar espaço.

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
1. Baixar o código fonte do Tailscale v1.68.1
2. Compilar para arquitetura mipsel_24kc com otimizações
3. Aplicar strip e compressão XZ
4. Gerar o binário `tailscaled.xz` (~4.9MB)

### Empacotamento

Para criar o pacote IPK com compressão XZ (recomendado):

```bash
./package-xz.sh
```

Para criar o pacote IPK com UPX (maior, sem dependência xz):

```bash
./package-minimal.sh
```

## Instalação

### Via IPK (Recomendado)

Copie o arquivo IPK para o roteador:

```bash
scp output/tailscale-zlan9809m-xz_1.68.1-1_mipsel_24kc.ipk root@router-ip:/tmp/
```

No roteador:

```bash
opkg update
opkg install xz
opkg install /tmp/tailscale-zlan9809m-xz_1.68.1-1_mipsel_24kc.ipk
```

**Nota:** O binário será descomprimido automaticamente na primeira inicialização. Isso pode levar alguns segundos.

### Via Script de Instalação

Execute o script de instalação no roteador:

```bash
./install.sh
```

### Manual

```bash
opkg install kmod-tun ca-bundle
chmod +x /usr/sbin/tailscaled
/etc/init.d/tailscale enable
/etc/init.d/tailscale start
```

## Configuração

### Via CLI (Recomendado para pacote minimal)

```bash
# Configurar via UCI
uci set tailscale.@tailscale[0].enabled='1'
uci set tailscale.@tailscale[0].auth_key='tskey-auth-SEU-KEY-AQUI'
uci set tailscale.@tailscale[0].advertise_routes='192.168.1.0/24'
uci set tailscale.@tailscale[0].accept_routes='1'
uci set tailscale.@tailscale[0].accept_dns='1'
uci commit tailscale

# Iniciar serviço
/etc/init.d/tailscale start
/etc/init.d/tailscale enable

# Verificar status
tailscale status
```

### Via LuCI (Opcional)

Se você instalou os arquivos LuCI manualmente, acesse:
`http://router-ip/cgi-bin/luci/admin/network/tailscale`

## Licença

MIT License - Ver arquivo LICENSE para detalhes.
