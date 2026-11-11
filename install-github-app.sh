
#!/bin/bash
set -Eeuo pipefail

# ==========================================================
# GitHub App Bootstrap Installer
# ==========================================================

GITHUB_OWNER="HGSM-Dr-Manoel-Bifulco"
GITHUB_REPO="hgsm_ghapp"

BASE_URL="https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/refs/heads/main/"

CONFIG_DIR="/etc/github-app"
AUTH_DEST="${CONFIG_DIR}/github-auth"
CONFIG_DEST="${CONFIG_DIR}/config"
EXAMPLE_DEST="${CONFIG_DIR}/config.example"
PEM_DEST="${CONFIG_DIR}/private-key.pem"
PULL_DEST="/usr/local/bin/github-pull"

TEMP_DIR=""

# ==========================================================
# Funções
# ==========================================================

cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

error() {
    echo "ERRO: $*" >&2
    exit 1
}

# ==========================================================
# Verificações
# ==========================================================

if [[ $EUID -ne 0 ]]; then
    error "Execute como root: sudo bash install-github-app.sh"
fi

if [[ $# -ne 0 && $# -ne 2 ]]; then
    error "Uso: install-github-app.sh [APP_ID INSTALLATION_ID]"
fi

# ==========================================================
# Localiza os arquivos de origem
# ==========================================================

if [[ -f "${BASH_SOURCE[0]}" && -f "$(dirname "${BASH_SOURCE[0]}")/github-auth" ]]; then

    # Execução local
    SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

else

    # Execução via curl | bash
    TEMP_DIR="$(mktemp -d)"
    SOURCE_DIR="$TEMP_DIR"

    echo "Baixando arquivos do GitHub..."

    for FILE in github-auth github-pull config.example; do
        curl -fsSL "${BASE_URL}/${FILE}" -o "${SOURCE_DIR}/${FILE}" \
            || error "Falha ao baixar ${FILE}."
    done

fi

# ==========================================================
# Valida os arquivos
# ==========================================================

for FILE in github-auth github-pull config.example; do
    [[ -s "${SOURCE_DIR}/${FILE}" ]] \
        || error "Arquivo ausente ou vazio: ${FILE}"
done

# ==========================================================
# Instala arquivos
# ==========================================================

install -d -o root -g root -m 700 "$CONFIG_DIR"

install -o root -g root -m 700 \
    "${SOURCE_DIR}/github-auth" "$AUTH_DEST"

install -o root -g root -m 755 \
    "${SOURCE_DIR}/github-pull" "$PULL_DEST"

install -o root -g root -m 644 \
    "${SOURCE_DIR}/config.example" "$EXAMPLE_DEST"

echo
echo "Arquivos instalados."

# ==========================================================
# Configuração
# ==========================================================

if [[ -f "$CONFIG_DEST" ]]; then

    echo "Configuração existente preservada."

else

    if [[ $# -eq 2 ]]; then
        APP_ID="$1"
        INSTALLATION_ID="$2"
    else
        read -r -p "APP_ID (Enter para usar exemplo): " APP_ID
        read -r -p "INSTALLATION_ID (Enter para usar exemplo): " INSTALLATION_ID
    fi

    if [[ -z "$APP_ID" && -z "$INSTALLATION_ID" ]]; then

        install -o root -g root -m 600 \
            "$EXAMPLE_DEST" "$CONFIG_DEST"

        echo "Configuração de exemplo criada."

    elif [[ -z "$APP_ID" || -z "$INSTALLATION_ID" ]]; then

        error "Informe os dois IDs ou deixe ambos vazios."

    elif [[ ! "$APP_ID" =~ ^[0-9]+$ || ! "$INSTALLATION_ID" =~ ^[0-9]+$ ]]; then

        error "Os IDs devem ser numéricos."

    else

        TEMP_CONFIG="$(mktemp "${CONFIG_DIR}/config.XXXXXX")"

        cat > "$TEMP_CONFIG" <<EOF
APP_ID="${APP_ID}"
INSTALLATION_ID="${INSTALLATION_ID}"
GITHUB_OWNER="${GITHUB_OWNER}"
EOF

        chown root:root "$TEMP_CONFIG"
        chmod 600 "$TEMP_CONFIG"
        mv "$TEMP_CONFIG" "$CONFIG_DEST"

        echo "Configuração criada."

    fi

fi

# ==========================================================
# Finalização
# ==========================================================

echo
echo "=========================================="
echo " GitHub App instalado"
echo "=========================================="
echo
echo "Chave privada PEM:"
echo "  ${PEM_DEST}"
echo
echo "Copie sua chave privada para esse caminho."
echo
echo "Permissões recomendadas:"
echo "  sudo chown root:root ${PEM_DEST}"
echo "  sudo chmod 600 ${PEM_DEST}"
echo
echo "Teste de autenticação:"
echo "  sudo ${AUTH_DEST} ${GITHUB_OWNER}/HGSM-noc"
echo
echo "Utilitário Git:"
echo "  sudo github-pull ${GITHUB_OWNER}/HGSM-noc /opt/noc"
echo
