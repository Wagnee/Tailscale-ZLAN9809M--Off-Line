# Guia de Instalação Completo - Tailscale para ZLAN9809M

## Requisitos

- Roteador ZLAN9809M com OpenWrt
- Mínimo de 5MB de espaço livre no overlay
- Acesso SSH ao roteador
- Conta Tailscale (https://tailscale.com)
- Auth key do Tailscale (obtenha em https://tailscale.com/settings/keys)

## Pacotes Disponíveis

### Pacote Core (Essencial)
- `tailscale-zlan9809m-core_1.68.1-1_mipsel_24kc.ipk` - 4.8MB
- Binário XZ comprimido
- Scripts essenciais
- Dependências: kmod-tun, ca-bundle, xz

### Pacote LuCI (Opcional)
- `luci-app-tailscale-zlan9809m_1.68.1-1_mipsel_24kc.ipk` - 2.6KB
- Interface web LuCI
- Dependência: tailscale-zlan9809m-core

## Métodos de Instalação

### Método 1: Via IPK (Recomendado)

#### Passo 1: Transferir pacotes para o roteador

```bash
# Transferir pacote core
scp output/tailscale-zlan9809m-core_1.68.1-1_mipsel_24kc.ipk root@router-ip:/tmp/

# Transferir pacote LuCI (opcional)
scp output/luci-app-tailscale-zlan9809m_1.68.1-1_mipsel_24kc.ipk root@router-ip:/tmp/
```

#### Passo 2: Instalar no roteador

```bash
# SSH no roteador
ssh root@router-ip

# Verificar espaço disponível
df -h /overlay

# Instalar dependências
opkg update
opkg install kmod-tun ca-bundle xz

# Instalar pacote core
opkg install /tmp/tailscale-zlan9809m-core_1.68.1-1_mipsel_24kc.ipk

# Instalar pacote LuCI (opcional)
opkg install /tmp/luci-app-tailscale-zlan9809m_1.68.1-1_mipsel_24kc.ipk
/etc/init.d/uhttpd restart
```

#### Passo 3: Configurar

```bash
# Configurar via CLI
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

### Método 2: Script de Instalação (Com Buffer de Memória)

Este método usa a memória RAM como buffer temporário para evitar problemas de espaço.

```bash
# Transferir script e pacotes
scp install.sh root@router-ip:/tmp/
scp output/tailscale-zlan9809m-core_1.68.1-1_mipsel_24kc.ipk root@router-ip:/tmp/
scp output/luci-app-tailscale-zlan9809m_1.68.1-1_mipsel_24kc.ipk root@router-ip:/tmp/

# SSH no roteador
ssh root@router-ip

# Executar script
cd /tmp
chmod +x install.sh
./install.sh
```

O script automaticamente:
- Verifica espaço disponível
- Se espaço < 5MB, cria tmpfs na memória
- Usa memória como buffer durante instalação
- Instala pacotes
- Limpa buffer após instalação

### Método 3: Instalação Manual

```bash
# SSH no roteador
ssh root@router-ip

# Instalar dependências
opkg update
opkg install kmod-tun ca-bundle xz

# Criar diretórios
mkdir -p /usr/sbin /etc/tailscale /etc/config /etc/init.d

# Copiar binário (depois de descomprimir)
xz -d tailscaled.xz
cp tailscaled /usr/sbin/
chmod +x /usr/sbin/tailscaled
ln -sf tailscaled /usr/sbin/tailscale

# Criar arquivo de configuração
cat > /etc/config/tailscale <<EOF
config tailscale 'tailscale'
    option enabled '0'
    option auth_key ''
    option accept_routes '1'
    option accept_dns '1'
    option advertise_routes ''
EOF

# Criar script de init (copiar do repositório)
# ...

# Habilitar e iniciar
/etc/init.d/tailscale enable
/etc/init.d/tailscale start
```

## Configuração

### Via CLI (Recomendado para economia de espaço)

```bash
# Habilitar Tailscale
uci set tailscale.@tailscale[0].enabled='1'

# Definir auth key
uci set tailscale.@tailscale[0].auth_key='tskey-auth-SEU-KEY-AQUI'

# Definir advertise routes (subrede LAN)
uci set tailscale.@tailscale[0].advertise_routes='192.168.1.0/24'

# Aceitar rotas de outros nodes
uci set tailscale.@tailscale[0].accept_routes='1'

# Aceitar DNS do tailnet
uci set tailscale.@tailscale[0].accept_dns='1'

# Salvar configuração
uci commit tailscale

# Reiniciar serviço
/etc/init.d/tailscale restart
```

### Via LuCI (Se instalado)

Acesse: `http://router-ip/cgi-bin/luci/admin/network/tailscale`

Configure:
- **Enable**: Marque para habilitar
- **Auth Key**: Cole sua auth key do Tailscale
- **Advertise Routes**: Digite o range da sua rede LAN (ex: 192.168.1.0/24)
- **Accept Routes**: Marque para aceitar rotas de outros nodes
- **Accept DNS**: Marque para usar DNS do tailnet

Clique em "Save & Apply"

## Verificação

```bash
# Verificar status do serviço
/etc/init.d/tailscale status

# Verificar status do Tailscale
tailscale status

# Verificar IP Tailscale
tailscale ip -4

# Verificar rotas anunciadas
tailscale status --json | grep AdvertisedRoutes

# Ver logs
logread | grep tailscale
```

## Solução de Problemas

### Erro: Espaço insuficiente

Se não houver espaço suficiente:
1. Use o script de instalação com buffer de memória
2. Remova pacotes não utilizados:
   ```bash
   opkg list-installed
   opkg remove <pacote>
   ```
3. Limpe cache opkg:
   ```bash
   opkg clean
   ```

### Erro: Binário não executa (Segmentation fault)

Se ocorrer segfault após descompressão:
1. Verifique se xz está instalado:
   ```bash
   opkg list-installed | grep xz
   ```
2. Se não estiver, instale:
   ```bash
   opkg install xz
   ```
3. Reinstale o pacote:
   ```bash
   opkg remove tailscale-zlan9809m-core
   opkg install /tmp/tailscale-zlan9809m-core_*.ipk
   ```

### Não consigo conectar

1. Verifique se o módulo tun está carregado:
   ```bash
   lsmod | grep tun
   ```
   Se não estiver:
   ```bash
   modprobe tun
   ```

2. Verifique logs:
   ```bash
   logread | grep tailscale
   ```

3. Verifique auth key:
   ```bash
   uci show tailscale
   ```

### Rotas não são anunciadas

1. Verifique se as rotas estão configuradas:
   ```bash
   uci show tailscale
   ```

2. Verifique status no Tailscale:
   ```bash
   tailscale status --json
   ```

3. Na interface web do Tailscale (admin console), vá em "Machine settings" e habilite as rotas.

## Persistência de Configuração

As configurações são salvas em:
- `/etc/config/tailscale` - Configuração UCI
- `/etc/tailscale/tailscale.state` - Estado do Tailscale

Esses arquivos são persistidos na memória flash do dispositivo (overlay).

## Atualização

Para atualizar para uma nova versão:

1. Pare o serviço:
   ```bash
   /etc/init.d/tailscale stop
   /etc/init.d/tailscale disable
   ```

2. Remover versão antiga:
   ```bash
   opkg remove tailscale-zlan9809m-core
   ```

3. Instalar nova versão:
   ```bash
   opkg install /tmp/tailscale-zlan9809m-core_*.ipk
   ```

4. Configuração será preservada em `/etc/config/tailscale`

## Desinstalação

```bash
/etc/init.d/tailscale stop
/etc/init.d/tailscale disable
opkg remove tailscale-zlan9809m-core

# Opcional: remover LuCI
opkg remove luci-app-tailscale-zlan9809m

# Remover arquivos manualmente
rm -rf /usr/sbin/tailscale /usr/sbin/tailscaled
rm -rf /etc/tailscale
rm -rf /etc/config/tailscale
rm -rf /etc/init.d/tailscale
```

## Funcionalidades

### Incluídas
- Conexão à tailnet especificada
- Advertise Routes da subrede DHCP
- Persistência de configuração
- Auto-detecção de range DHCP (via configuração manual)
- Configuração via CLI (UCI)
- Interface LuCI opcional

### Omitidas (para reduzir tamanho)
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
- SSH
- DNS extras

## Suporte

Para problemas específicos do Tailscale:
- Documentação oficial: https://tailscale.com/kb/
- Fórum do Tailscale: https://github.com/tailscale/tailscale/issues

Para problemas específicos do ZLAN9809M:
- Fórum OpenWrt: https://forum.openwrt.org/

## Informações Técnicas

- **Versão do Tailscale**: 1.68.1
- **Arquitetura**: MIPS 24Kc (MT7628NN)
- **Compilação**: Go 1.22 com flags de otimização
- **Compressão**: XZ (--extreme)
- **Tamanho do binário**: 4.8MB (comprimido)
- **Tamanho original**: 23MB (descomprimido)
- **Tags de build**: ts_omit_aws, ts_omit_bird, ts_omit_completion, ts_omit_kube, ts_omit_systray, ts_omit_taildrop, ts_omit_tap, ts_omit_tpm, ts_omit_relayserver, ts_omit_capture, ts_omit_syspolicy, ts_omit_debugeventbus, ts_omit_webclient, ts_omit_userspaceingress
