# Guia de Execução Remota de Scripts com Segurança

## Opção 1: Assinatura de Scripts com GPG

### Conceito

Usar GPG (GNU Privacy Guard) para assinar digitalmente scripts. O script só executa se a assinatura for válida e de uma chave confiável.

### Como Funciona

```
┌─────────────────────────────────────────────────────────┐
│ Desenvolvedor (PC)                                      │
│                                                         │
│ 1. Criar chave GPG                                     │
│ 2. Assinar script.sh com chave privada                 │
│ 3. Upload script.sh + script.sh.sig para GitHub        │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│ Repositório GitHub                                      │
│                                                         │
│ script.sh (script assinado)                             │
│ script.sh.sig (assinatura digital)                     │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│ Roteador ZLAN9809M                                      │
│                                                         │
│ 1. Baixar script.sh + script.sh.sig                    │
│ 2. Importar chave pública GPG do desenvolvedor         │
│ 3. Verificar assinatura: gpg --verify script.sh.sig     │
│ 4. Se válida: executar script.sh                        │
│ 5. Se inválida: recusar execução                        │
└─────────────────────────────────────────────────────────┘
```

### Implementação

#### Passo 1: Criar Chave GPG (Desenvolvedor)

```bash
# No PC do desenvolvedor
gpg --full-generate-key

# Opções:
# Tipo de chave: RSA and RSA
# Tamanho: 4096 bits
# Validade: 1 ano (ou sem expiração)
# Nome: "Tailscale ZLAN9809M Project"
# Email: dev@tailscale-zlan9809m.com
# Senha: [senha forte]
```

#### Passo 2: Exportar Chave Pública

```bash
# Exportar chave pública para distribuir
gpg --export --armor dev@tailscale-zlan9809m.com > public_key.asc

# Exportar chave privada (backup seguro)
gpg --export-secret-keys --armor dev@tailscale-zlan9809m.com > private_key.asc
```

#### Passo 3: Assinar Script

```bash
# Assinar script
gpg --default-key dev@tailscale-zlan9809m.com --detach-sign --armor script.sh

# Resulta em:
# script.sh (original)
# script.sh.asc (assinatura)
```

#### Passo 4: Distribuir Chave Pública (Roteador)

```bash
# No roteador, instalar gnupg
opkg update
opkg install gnupg

# Importar chave pública do desenvolvedor
curl -s https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main/keys/public_key.asc | gpg --import

# Definir confiança (trust ultimate)
gpg --edit-key dev@tailscale-zlan9809m.com
# Comando: trust
# Opção: 5 (I trust ultimately)
# Comando: save
```

#### Passo 5: Script de Verificação e Execução

```bash
#!/bin/bash
# verify-and-execute.sh - Verifica assinatura GPG e executa script

SCRIPT_URL="$1"
SIG_URL="$2"
SIGNER_EMAIL="dev@tailscale-zlan9809m.com"

# Baixar script e assinatura
curl -s "$SCRIPT_URL" -o /tmp/script.sh
curl -s "$SIG_URL" -o /tmp/script.sh.asc

# Verificar assinatura
if gpg --verify --keyring ~/.gnupg/pubring.kbx /tmp/script.sh.asc /tmp/script.sh 2>&1 | grep -q "Good signature from \"$SIGNER_EMAIL\""; then
    echo "Assinatura válida. Executando script..."
    chmod +x /tmp/script.sh
    /tmp/script.sh
    EXIT_CODE=$?
    rm /tmp/script.sh /tmp/script.sh.asc
    exit $EXIT_CODE
else
    echo "ERRO: Assinatura inválida ou não confiável. Execução recusada."
    rm /tmp/script.sh /tmp/script.sh.asc
    exit 1
fi
```

#### Passo 6: Daemon de Auto-Update com Verificação GPG

```bash
#!/bin/bash
# auto-update-daemon-gpg.sh - Auto-update com verificação GPG

REPO_URL="https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main/scripts"
SIGNER_EMAIL="dev@tailscale-zlan9809m.com"
CHECK_INTERVAL=600  # 10 minutos
EXECUTED_SCRIPTS_DIR="/var/lib/auto-update-executed"

mkdir -p "$EXECUTED_SCRIPTS_DIR"

while true; do
    echo "[$(date)] Verificando scripts no repositório..."
    
    # Baixar lista de scripts
    SCRIPTS=$(curl -s "$REPO_URL/" | grep -oP 'href="\K[^"]+\.sh(?=")')
    
    for script in $SCRIPTS; do
        script_url="$REPO_URL/$script"
        sig_url="$REPO_URL/$script.asc"
        
        # Baixar script e assinatura
        curl -s "$script_url" -o "/tmp/$script"
        curl -s "$sig_url" -o "/tmp/$script.asc"
        
        # Calcular hash do script
        HASH=$(md5sum "/tmp/$script" | awk '{print $1}')
        
        # Verificar se já foi executado
        if [ -f "$EXECUTED_SCRIPTS_DIR/$script.hash" ] && [ "$(cat $EXECUTED_SCRIPTS_DIR/$script.hash)" = "$HASH" ]; then
            echo "[$(date)] Script $script já executado (hash igual). Pulando."
            rm "/tmp/$script" "/tmp/$script.asc"
            continue
        fi
        
        # Verificar assinatura GPG
        echo "[$(date)] Verificando assinatura de $script..."
        if gpg --verify --keyring ~/.gnupg/pubring.kbx "/tmp/$script.asc" "/tmp/$script" 2>&1 | grep -q "Good signature from \"$SIGNER_EMAIL\""; then
            echo "[$(date)] Assinatura válida. Executando $script..."
            chmod +x "/tmp/$script"
            
            # Executar em subshell com timeout
            timeout 300 /tmp/$script 2>&1 | tee "/var/log/auto-update-$script.log"
            EXIT_CODE=${PIPESTATUS[0]}
            
            if [ $EXIT_CODE -eq 0 ]; then
                echo "[$(date)] Script $script executado com sucesso."
                echo "$HASH" > "$EXECUTED_SCRIPTS_DIR/$script.hash"
            else
                echo "[$(date)] ERRO: Script $script falhou com código $EXIT_CODE."
            fi
            
            rm "/tmp/$script" "/tmp/$script.asc"
        else
            echo "[$(date)] ERRO: Assinatura inválida para $script. Execução recusada."
            rm "/tmp/$script" "/tmp/$script.asc"
        fi
    done
    
    sleep $CHECK_INTERVAL
done
```

### Vantagens

- ✅ **Alta segurança**: Só executa scripts assinados por chave confiável
- ✅ **Integridade**: Garante que script não foi modificado
- ✅ **Autenticidade**: Garante que script veio do desenvolvedor
- ✅ **Rastreabilidade**: Pode identificar quem assinou

### Desvantagens

- ⚠️ **Complexidade**: Requer gerenciamento de chaves GPG
- ⚠️ **Overhead**: Verificação de assinatura consome recursos
- ⚠️ **Gerenciamento**: Chave privada deve ser protegida
- ⚠️ **Revogação**: Se chave for comprometida, precisa revogar e redistribuir

---

## Opção 2: Whitelist de Scripts

### Conceito

Manter uma lista pré-definida de scripts permitidos. Só executa scripts que estão na whitelist.

### Como Funciona

```
┌─────────────────────────────────────────────────────────┐
│ Repositório GitHub                                      │
│                                                         │
│ update-firmware.sh      (permitido)                      │
│ config-backup.sh       (permitido)                      │
│ system-check.sh        (permitido)                      │
│ malicious-script.sh    (NÃO permitido - não executa)    │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│ Roteador ZLAN9809M                                      │
│                                                         │
│ Whitelist (configurada):                                │
│ - update-firmware.sh                                   │
│ - config-backup.sh                                      │
│ - system-check.sh                                       │
│                                                         │
│ 1. Baixar script                                       │
│ 2. Verificar se está na whitelist                      │
│ 3. Se SIM: executar                                    │
│ 4. Se NÃO: recusar e logar                             │
└─────────────────────────────────────────────────────────┘
```

### Implementação

#### Passo 1: Definir Whitelist

```bash
# /etc/auto-update-whitelist.conf
# Whitelist de scripts permitidos para execução automática

# Formato: nome_script.sh:descrição
update-firmware.sh:Atualiza firmware do roteador
config-backup.sh:Faz backup das configurações
system-check.sh:Verifica saúde do sistema
log-rotate.sh:Rotaciona logs antigos
cache-clear.sh:Limpa cache do sistema
```

#### Passo 2: Script de Verificação de Whitelist

```bash
#!/bin/bash
# check-whitelist.sh - Verifica se script está na whitelist

SCRIPT_NAME="$1"
WHITELIST_FILE="/etc/auto-update-whitelist.conf"

if [ ! -f "$WHITELIST_FILE" ]; then
    echo "ERRO: Arquivo de whitelist não encontrado: $WHITELIST_FILE"
    exit 1
fi

# Verificar se script está na whitelist
if grep -q "^${SCRIPT_NAME}:" "$WHITELIST_FILE"; then
    echo "Script $SCRIPT_NAME está na whitelist."
    exit 0
else
    echo "Script $SCRIPT_name NÃO está na whitelist. Execução recusada."
    exit 1
fi
```

#### Passo 3: Daemon de Auto-Update com Whitelist

```bash
#!/bin/bash
# auto-update-daemon-whitelist.sh - Auto-update com whitelist

REPO_URL="https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main/scripts"
WHITELIST_FILE="/etc/auto-update-whitelist.conf"
CHECK_INTERVAL=600  # 10 minutos
EXECUTED_SCRIPTS_DIR="/var/lib/auto-update-executed"

mkdir -p "$EXECUTED_SCRIPTS_DIR"

while true; do
    echo "[$(date)] Verificando scripts no repositório..."
    
    # Baixar lista de scripts
    SCRIPTS=$(curl -s "$REPO_URL/" | grep -oP 'href="\K[^"]+\.sh(?=")')
    
    for script in $SCRIPTS; do
        # Verificar se está na whitelist
        if ! grep -q "^${script}:" "$WHITELIST_FILE"; then
            echo "[$(date)] Script $script NÃO está na whitelist. Pulando."
            continue
        fi
        
        script_url="$REPO_URL/$script"
        
        # Baixar script
        curl -s "$script_url" -o "/tmp/$script"
        
        # Calcular hash do script
        HASH=$(md5sum "/tmp/$script" | awk '{print $1}')
        
        # Verificar se já foi executado
        if [ -f "$EXECUTED_SCRIPTS_DIR/$script.hash" ] && [ "$(cat $EXECUTED_SCRIPTS_DIR/$script.hash)" = "$HASH" ]; then
            echo "[$(date)] Script $script já executado (hash igual). Pulando."
            rm "/tmp/$script"
            continue
        fi
        
        # Executar script
        echo "[$(date)] Executando script permitido: $script"
        chmod +x "/tmp/$script"
        
        # Executar em subshell com timeout
        timeout 300 /tmp/$script 2>&1 | tee "/var/log/auto-update-$script.log"
        EXIT_CODE=${PIPESTATUS[0]}
        
        if [ $EXIT_CODE -eq 0 ]; then
            echo "[$(date)] Script $script executado com sucesso."
            echo "$HASH" > "$EXECUTED_SCRIPTS_DIR/$script.hash"
        else
            echo "[$(date)] ERRO: Script $script falhou com código $EXIT_CODE."
        fi
        
        rm "/tmp/$script"
    done
    
    sleep $CHECK_INTERVAL
done
```

#### Passo 4: Gerenciar Whitelist via UCI

```bash
# Criar configuração UCI para whitelist
cat > /etc/config/auto-update <<'EOF'
config auto-update 'settings'
    option enabled '1'
    option repo_url 'https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main/scripts'
    option check_interval '600'

config whitelist 'update-firmware'
    option enabled '1'
    option name 'update-firmware.sh'
    option description 'Atualiza firmware do roteador'

config whitelist 'config-backup'
    option enabled '1'
    option name 'config-backup.sh'
    option description 'Faz backup das configurações'

config whitelist 'system-check'
    option enabled '1'
    option name 'system-check.sh'
    option description 'Verifica saúde do sistema'
EOF
```

#### Passo 5: Script de Verificação de Whitelist UCI

```bash
#!/bin/bash
# check-whitelist-uci.sh - Verifica whitelist via UCI

SCRIPT_NAME="$1"

# Verificar se script está na whitelist UCI
if uci get auto-update.$SCRIPT_NAME >/dev/null 2>&1; then
    ENABLED=$(uci get auto-update.$SCRIPT_NAME.enabled)
    if [ "$ENABLED" = "1" ]; then
        echo "Script $SCRIPT_NAME está na whitelist e habilitado."
        exit 0
    else
        echo "Script $SCRIPT_NAME está na whitelist mas desabilitado."
        exit 1
    fi
else
    echo "Script $SCRIPT_NAME NÃO está na whitelist. Execução recusada."
    exit 1
fi
```

### Vantagens

- ✅ **Simplicidade**: Fácil de implementar e entender
- ✅ **Controle**: Apenas scripts pré-aprovados executam
- ✅ **Gerenciamento**: Fácil adicionar/remover scripts
- ✅ **Transparência**: Lista visível de scripts permitidos

### Desvantagens

- ⚠️ **Menos segurança**: Não garante integridade do script
- ⚠️ **Comprometimento**: Se repositório for comprometido, script malicioso pode substituir script permitido
- ⚠️ **Manutenção**: Requer atualização manual da whitelist

---

## Combinação: Whitelist + Assinatura GPG (Recomendado)

### Conceito

Combinar whitelist com assinatura GPG para máxima segurança:
- Script deve estar na whitelist
- Script deve ter assinatura GPG válida
- Só executa se ambas as condições forem atendidas

### Implementação

```bash
#!/bin/bash
# auto-update-daemon-hybrid.sh - Auto-update com whitelist + GPG

REPO_URL="https://raw.githubusercontent.com/Wagnee/Tailscale-ZLAN9809M--Off-Line/main/scripts"
WHITELIST_FILE="/etc/auto-update-whitelist.conf"
SIGNER_EMAIL="dev@tailscale-zlan9809m.com"
CHECK_INTERVAL=600
EXECUTED_SCRIPTS_DIR="/var/lib/auto-update-executed"

mkdir -p "$EXECUTED_SCRIPTS_DIR"

while true; do
    echo "[$(date)] Verificando scripts no repositório..."
    
    SCRIPTS=$(curl -s "$REPO_URL/" | grep -oP 'href="\K[^"]+\.sh(?=")')
    
    for script in $SCRIPTS; do
        # 1. Verificar whitelist
        if ! grep -q "^${script}:" "$WHITELIST_FILE"; then
            echo "[$(date)] Script $script NÃO está na whitelist. Pulando."
            continue
        fi
        
        script_url="$REPO_URL/$script"
        sig_url="$REPO_URL/$script.asc"
        
        # 2. Baixar script e assinatura
        curl -s "$script_url" -o "/tmp/$script"
        curl -s "$sig_url" -o "/tmp/$script.asc"
        
        # 3. Calcular hash
        HASH=$(md5sum "/tmp/$script" | awk '{print $1}')
        
        # 4. Verificar se já foi executado
        if [ -f "$EXECUTED_SCRIPTS_DIR/$script.hash" ] && [ "$(cat $EXECUTED_SCRIPTS_DIR/$script.hash)" = "$HASH" ]; then
            echo "[$(date)] Script $script já executado (hash igual). Pulando."
            rm "/tmp/$script" "/tmp/$script.asc"
            continue
        fi
        
        # 5. Verificar assinatura GPG
        echo "[$(date)] Verificando assinatura de $script..."
        if ! gpg --verify --keyring ~/.gnupg/pubring.kbx "/tmp/$script.asc" "/tmp/$script" 2>&1 | grep -q "Good signature from \"$SIGNER_EMAIL\""; then
            echo "[$(date)] ERRO: Assinatura inválida para $script. Execução recusada."
            rm "/tmp/$script" "/tmp/$script.asc"
            continue
        fi
        
        # 6. Executar script (ambas as verificações passaram)
        echo "[$(date)] Executando script permitido e assinado: $script"
        chmod +x "/tmp/$script"
        
        timeout 300 /tmp/$script 2>&1 | tee "/var/log/auto-update-$script.log"
        EXIT_CODE=${PIPESTATUS[0]}
        
        if [ $EXIT_CODE -eq 0 ]; then
            echo "[$(date)] Script $script executado com sucesso."
            echo "$HASH" > "$EXECUTED_SCRIPTS_DIR/$script.hash"
        else
            echo "[$(date)] ERRO: Script $script falhou com código $EXIT_CODE."
        fi
        
        rm "/tmp/$script" "/tmp/$script.asc"
    done
    
    sleep $CHECK_INTERVAL
done
```

### Vantagens da Combinação

- ✅ **Máxima segurança**: Whitelist + Assinatura GPG
- ✅ **Defesa em profundidade**: Múltiplas camadas de verificação
- ✅ **Flexibilidade**: Fácil gerenciar whitelist
- ✅ **Integridade**: Garante que script não foi modificado

### Desvantagens da Combinação

- ⚠️ **Complexidade**: Requer gerenciamento de chaves e whitelist
- ⚠️ **Overhead**: Duas verificações por script
- ⚠️ **Manutenção**: Chave GPG + whitelist

---

## Comparativo das Opções

| Característica | Whitelist | GPG | Hybrid (Ambas) |
|----------------|-----------|-----|----------------|
| Segurança | Média | Alta | Muito Alta |
| Complexidade | Baixa | Alta | Muito Alta |
| Integridade | Não garante | Garante | Garante |
| Autenticidade | Não garante | Garante | Garante |
| Manutenção | Baixa | Alta | Alta |
| Overhead | Baixo | Médio | Médio-Alto |

---

## Recomendação Final

**Para seu caso de uso (ZLAN9809M):**

1. **Se segurança é crítica**: Use **GPG + Whitelist** (Hybrid)
   - Máxima segurança
   - Garante integridade e autenticidade
   - Defesa em profundidade

2. **Se simplicidade é prioridade**: Use **Whitelist**
   - Fácil de implementar
   - Controle claro de scripts
   - Menos overhead

3. **Se recursos são limitados**: Use **Whitelist**
   - Menor overhead de CPU/RAM
   - Não requer gnupg

**Para produção:** Recomendo **Hybrid (Whitelist + GPG)** para máxima segurança.

**Para desenvolvimento/testes:** Recomendo **Whitelist** para simplicidade.
