#!/usr/bin/env bash

register_plugin sdk "Antigravity SDK Python (google-antigravity)"

readonly SDK_PACKAGE_NAME="google-antigravity"
SDK_PIP=""

_sdk_pip() {
    if command -v pip3 >/dev/null 2>&1; then
        printf 'pip3'
    elif command -v pip >/dev/null 2>&1; then
        printf 'pip'
    fi
}

_sdk_require_pip() {
    SDK_PIP="$(_sdk_pip)"
    if [[ -z "${SDK_PIP}" ]]; then
        c_err "pip3 ou pip é necessário para gerenciar o Antigravity SDK."
        return 1
    fi
}

_sdk_installed_version() {
    local pip_command

    pip_command="$(_sdk_pip)"
    [[ -n "${pip_command}" ]] || return 1
    "${pip_command}" show "${SDK_PACKAGE_NAME}" 2>/dev/null \
        | awk -F': ' '/^Version:/ {print $2; exit}'
}

sdk_install() {
    local current_version

    _sdk_require_pip || return 1
    current_version="$(_sdk_installed_version || true)"
    if [[ -n "${current_version}" ]]; then
        c_warn "Antigravity SDK ${current_version} já está instalado. Use 'agv update sdk'."
        return 0
    fi

    "${SDK_PIP}" install --user "${SDK_PACKAGE_NAME}" || {
        c_err "Falha ao instalar o Antigravity SDK."
        return 1
    }

    c_ok "Antigravity SDK instalado com sucesso."
    c_info "Defina GEMINI_API_KEY antes de usar o SDK."
}

sdk_update() {
    _sdk_require_pip || return 1
    "${SDK_PIP}" install --user --upgrade "${SDK_PACKAGE_NAME}" || {
        c_err "Falha ao atualizar o Antigravity SDK."
        return 1
    }

    c_ok "Antigravity SDK instalado ou atualizado com sucesso."
    c_info "Defina GEMINI_API_KEY antes de usar o SDK."
}

sdk_status() {
    local current_version

    if [[ -z "$(_sdk_pip)" ]]; then
        c_warn "Antigravity SDK não pode ser consultado: pip3 ou pip não está disponível."
        return 0
    fi

    current_version="$(_sdk_installed_version || true)"
    if [[ -n "${current_version}" ]]; then
        c_ok "Antigravity SDK instalado: ${current_version}"
    else
        c_warn "Antigravity SDK não está instalado."
    fi
}

sdk_uninstall() {
    local current_version

    _sdk_require_pip || return 1
    current_version="$(_sdk_installed_version || true)"
    if [[ -z "${current_version}" ]]; then
        c_warn "Antigravity SDK não está instalado."
        return 0
    fi

    "${SDK_PIP}" uninstall -y "${SDK_PACKAGE_NAME}" || {
        c_err "Falha ao desinstalar o Antigravity SDK."
        return 1
    }

    c_ok "Antigravity SDK removido."
}
