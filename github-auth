#!/bin/bash
set -Eeuo pipefail

CONFIG="/etc/github-app/config"
PRIVATE_KEY="/etc/github-app/private-key.pem"

REPOSITORY="${1:?Uso: github-auth.sh ORGANIZACAO/REPOSITORIO}"

# Verifica arquivos
if [[ ! -r "$CONFIG" || ! -r "$PRIVATE_KEY" ]]; then
    echo "Configuração ou chave privada não encontrada." >&2
    exit 1
fi

# Carrega configurações confiáveis
source "$CONFIG"

: "${APP_ID:?APP_ID não definido}"
: "${INSTALLATION_ID:?INSTALLATION_ID não definido}"
: "${GITHUB_OWNER:?GITHUB_OWNER não definido}"

# Valida identificadores
if [[ ! "$APP_ID" =~ ^[0-9]+$ || ! "$INSTALLATION_ID" =~ ^[0-9]+$ ]]; then
    echo "APP_ID ou INSTALLATION_ID inválido." >&2
    exit 1
fi

# Valida repositório
if [[ ! "$REPOSITORY" =~ ^([A-Za-z0-9-]+)/([A-Za-z0-9._-]+)$ ]]; then
    echo "Formato inválido. Use ORGANIZACAO/REPOSITORIO." >&2
    exit 1
fi

OWNER="${BASH_REMATCH[1]}"
REPO="${BASH_REMATCH[2]}"

if [[ "$OWNER" != "$GITHUB_OWNER" ]]; then
    echo "Organização diferente da configurada no GitHub App." >&2
    exit 1
fi

# Dependências
for cmd in openssl curl jq; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Dependência ausente: $cmd" >&2
        exit 1
    }
done

# Codificação Base64 URL-safe
base64url() {
    openssl base64 -A | tr '+/' '-_' | tr -d '='
}

# Gera JWT
NOW=$(date +%s)
IAT=$((NOW - 60))
EXP=$((NOW + 540))

HEADER=$(
    printf '%s' '{"alg":"RS256","typ":"JWT"}' |
    base64url
)

PAYLOAD=$(
    jq -cn \
        --arg iss "$APP_ID" \
        --argjson iat "$IAT" \
        --argjson exp "$EXP" \
        '{iss:$iss, iat:$iat, exp:$exp}' |
    base64url
)

UNSIGNED="${HEADER}.${PAYLOAD}"

SIGNATURE=$(
    printf '%s' "$UNSIGNED" |
    openssl dgst -sha256 -sign "$PRIVATE_KEY" -binary |
    base64url
)

JWT="${UNSIGNED}.${PAYLOAD}"
JWT="${HEADER}.${PAYLOAD}.${SIGNATURE}"

# Solicita token limitado ao repositório
BODY=$(jq -cn --arg repo "$REPO" '{repositories:[$repo]}')

RESPONSE=$(
    curl --config - <<EOF
url = "https://api.github.com/app/installations/${INSTALLATION_ID}/access_tokens"
request = "POST"
header = "Accept: application/vnd.github+json"
header = "Authorization: Bearer ${JWT}"
header = "X-GitHub-Api-Version: 2022-11-28"
header = "Content-Type: application/json"
data = "${BODY}"
silent
show-error
fail
EOF
)

# Retorna somente o token
printf '%s' "$RESPONSE" | jq -er '.token | strings | select(length > 0)'
