# Guia de Uso - Tailscale para ZLAN9809M

## Pré-requisitos

- Roteador ZLAN9809M com OpenWrt instalado
- Acesso SSH ao roteador
- Conta Tailscale (https://tailscale.com)
- Auth key do Tailscale (obtenha em https://tailscale.com/settings/keys)

## Compilação

### No Linux/WSL2

1. Instale dependências:
```bash
sudo apt update
sudo apt install golang git upx binutils-mipsel-linux-gnu
```

2. Clone o repositório:
```bash
cd Tailscale-ZLAN9809M--Off-Line
```

3. Execute o script de compilação:
```bash
chmod +x build.sh
./build.sh
```

4. Crie o pacote IPK (opcional):
```bash
chmod +x package.sh
./package.sh
```

O binário compilado estará em `output/tailscaled`.

## Instalação

### Método 1: Usando o script de instalação

1. Copie todo o diretório para o roteador (via SCP):
```bash
scp -r Tailscale-ZLAN9809M--Off-Line root@router-ip:/tmp/
```

2. No roteador:
```bash
cd /tmp/Tailscale-ZLAN9809M--Off-Line
chmod +x install.sh
./install.sh
```

### Método 2: Usando pacote IPK

1. Copie o arquivo .ipk para o roteador:
```bash
scp output/tailscale-zlan9809m_*.ipk root@router-ip:/tmp/
scp opkg-preflight.sh root@router-ip:/tmp/
```

2. No roteador:
```bash
chmod +x /tmp/opkg-preflight.sh
/tmp/opkg-preflight.sh
opkg update
opkg install /tmp/tailscale-zlan9809m_*.ipk
```

### Método 3: Instalação manual

1. Copie o binário:
```bash
scp output/tailscaled root@router-ip:/tmp/
scp opkg-preflight.sh root@router-ip:/tmp/
```

2. No roteador:
```bash
chmod +x /tmp/opkg-preflight.sh
/tmp/opkg-preflight.sh
opkg update
opkg install kmod-tun ca-bundle ip-full ipset ipset6
mkdir -p /usr/sbin /etc/tailscale /etc/config /etc/init.d /etc/hotplug.d/iface /etc/uci-defaults
cp /tmp/tailscaled /usr/sbin/tailscaled
chmod +x /usr/sbin/tailscaled
ln -sf /usr/sbin/tailscaled /usr/sbin/tailscale

# Copiar arquivos de configuração (do diretório files/)
```

## Configuração

### Via LuCI (Interface Web)

1. Acesse: `http://router-ip/cgi-bin/luci/admin/network/tailscale`
2. Configure:
   - **Enable**: Marque para habilitar
   - **Auth Key**: Cole sua auth key do Tailscale
   - **Advertise Routes**: Digite o range da sua rede LAN (ex: 192.168.1.0/24)
   - **Auto-detect DHCP Range**: Deixe marcado para detecção automática
3. Clique em "Save & Apply"
4. O serviço será iniciado automaticamente

### Via Linha de Comando

1. Configure via UCI:
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

# Iniciar serviço
/etc/init.d/tailscale start
/etc/init.d/tailscale enable
```

2. Verificar status:
```bash
tailscale status
```

3. Verificar IP Tailscale:
```bash
tailscale ip -4
```

## Configuração Avançada

### Advertise Exit Node

Para usar o roteador como exit node:

```bash
uci set tailscale.@tailscale[0].advertise_exit_node='1'
uci commit tailscale
/etc/init.d/tailscale restart
```

Depois, habilite na interface do Tailscale (admin console).

### Habilitar SSH via Tailscale

```bash
uci set tailscale.@tailscale[0].ssh='1'
uci commit tailscale
/etc/init.d/tailscale restart
```

### Múltiplas Rotas

Para anunciar múltiplas rotas (separadas por vírgula):
```bash
uci set tailscale.@tailscale[0].advertise_routes='192.168.1.0/24,192.168.2.0/24'
uci commit tailscale
/etc/init.d/tailscale restart
```

## Solução de Problemas

### Binário não executa (Segmentation fault)

Se ocorrer segfault, pode ser devido à compressão UPX. Recompile sem UPX:

Edite `build.sh` e comente a linha do UPX:
```bash
# upx --lzma --best --overlay=copy tailscale.combined
```

### Não consigo conectar

1. Verifique se o módulo tun está carregado:
```bash
lsmod | grep tun
```

2. Se não estiver, carregue manualmente:
```bash
modprobe tun
```

3. Verifique logs:
```bash
logread | grep tailscale
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

3. Na interface web do Tailscale, vá em "Machine settings" e habilite as rotas.

### Espaço insuficiente

Se não houver espaço suficiente, tente:
1. Remover pacotes não utilizados:
```bash
opkg list-installed | grep -v tailscale
opkg remove <pacote>
```

2. Limpar cache opkg:
```bash
opkg clean
```

3. Usar overlay externo (USB) se disponível.

## Atualização

Para atualizar para uma nova versão:

1. Pare o serviço:
```bash
/etc/init.d/tailscale stop
```

2. Substitua o binário:
```bash
cp /tmp/novo-tailscaled /usr/sbin/tailscaled
chmod +x /usr/sbin/tailscaled
```

3. Reinicie:
```bash
/etc/init.d/tailscale start
```

## Persistência de Configuração

As configurações são salvas em:
- `/etc/config/tailscale` - Configuração UCI
- `/etc/tailscale/tailscale.state` - Estado do Tailscale

Esses arquivos são persistidos na memória flash do dispositivo (overlay).

## Desinstalação

```bash
/etc/init.d/tailscale stop
/etc/init.d/tailscale disable
rm -rf /usr/sbin/tailscale /usr/sbin/tailscaled
rm -rf /etc/tailscale
rm -rf /etc/config/tailscale
rm -rf /etc/init.d/tailscale
rm -rf /etc/hotplug.d/iface/99-tailscale
rm -rf /usr/lib/lua/luci/controller/admin/tailscale.lua
rm -rf /usr/lib/lua/luci/controller/admin/tailscale_status.lua
rm -rf /usr/lib/lua/luci/model/cbi/tailscale.lua
rm -rf /usr/lib/lua/luci/view/tailscale
/etc/init.d/uhttpd restart
```

## Suporte

Para problemas específicos do Tailscale, consulte:
- Documentação oficial: https://tailscale.com/kb/
- Fórum do Tailscale: https://github.com/tailscale/tailscale/issues

Para problemas específicos do ZLAN9809M:
- Fórum OpenWrt: https://forum.openwrt.org/
