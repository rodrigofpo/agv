#!/usr/bin/env bash

register_plugin cli "Antigravity CLI (agy)"

readonly CLI_INSTALL_URL="https://antigravity.google/cli/install.sh"
readonly CLI_BIN="${HOME}/.local/bin/agy"

_cli_run_installer() {
    local -a statuses
    local curl_status
    local bash_status

    if ! command -v curl >/dev/null 2>&1; then
        c_err "curl é necessário para instalar o Antigravity CLI."
        return 1
    fi

    c_info "Executando o instalador oficial do Antigravity CLI..."
    curl -fsSL "${CLI_INSTALL_URL}" | bash
    statuses=("${PIPESTATUS[@]}")
    curl_status=${statuses[0]}
    bash_status=${statuses[1]}

    if (( curl_status != 0 )); then
        c_err "Falha ao baixar o instalador oficial do Antigravity CLI."
        return "${curl_status}"
    fi
    if (( bash_status != 0 )); then
        c_err "O instalador oficial do Antigravity CLI falhou."
        return "${bash_status}"
    fi
}

_cli_warn_path() {
    if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
        c_warn "${HOME}/.local/bin não está no PATH."
        c_warn "Adicione 'export PATH=\"${HOME}/.local/bin:\$PATH\"' à configuração do seu shell."
    fi
}

cli_install() {
    if [[ -x "${CLI_BIN}" ]]; then
        c_warn "Antigravity CLI já está instalado. Use 'agv update cli'."
        return 0
    fi

    _cli_run_installer || return 1
    _cli_warn_path

    if [[ ! -x "${CLI_BIN}" ]]; then
        c_err "O instalador terminou, mas ${CLI_BIN} não foi encontrado ou não é executável."
        return 1
    fi

    c_ok "Antigravity CLI instalado com sucesso."
}

cli_update() {
    _cli_run_installer || return 1
    _cli_warn_path

    if [[ ! -x "${CLI_BIN}" ]]; then
        c_err "O instalador terminou, mas ${CLI_BIN} não foi encontrado ou não é executável."
        return 1
    fi

    c_ok "Antigravity CLI instalado ou atualizado com sucesso."
}

cli_status() {
    local version

    if [[ ! -x "${CLI_BIN}" ]]; then
        c_warn "Antigravity CLI não está instalado em ${CLI_BIN}."
        return 0
    fi

    version="$("${CLI_BIN}" --version 2>/dev/null || true)"
    if [[ -n "${version}" ]]; then
        c_ok "Antigravity CLI instalado: ${version}"
    else
        c_ok "Antigravity CLI instalado: versão desconhecida"
    fi
}

cli_uninstall() {
    if [[ ! -e "${CLI_BIN}" ]]; then
        c_warn "Antigravity CLI não está instalado em ${CLI_BIN}."
        return 0
    fi

    rm -f "${CLI_BIN}" || {
        c_err "Não foi possível remover ${CLI_BIN}."
        return 1
    }

    c_ok "Antigravity CLI removido."
    c_info "Credenciais e configurações do agy não foram alteradas."
}
