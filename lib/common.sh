#!/usr/bin/env bash

# Cores ANSI usadas pelas mensagens do agv.
readonly C_RESET='\033[0m'
readonly C_BLUE='\033[0;34m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_RED='\033[0;31m'

c_info() { printf '%b[INFO]%b %s\n' "${C_BLUE}" "${C_RESET}" "$*"; }
c_ok()   { printf '%b[ OK ]%b %s\n' "${C_GREEN}" "${C_RESET}" "$*"; }
c_warn() { printf '%b[WARN]%b %s\n' "${C_YELLOW}" "${C_RESET}" "$*" >&2; }
c_err()  { printf '%b[ERRO]%b %s\n' "${C_RED}" "${C_RESET}" "$*" >&2; }

SUDO=""
require_sudo() {
    if (( EUID == 0 )); then
        SUDO=""
        return 0
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        c_err "Este comando requer privilégios administrativos, mas sudo não está disponível."
        return 1
    fi

    SUDO="sudo"
}

declare -a AGV_PLUGIN_NAMES=()
declare -A AGV_PLUGIN_DESC=()

register_plugin() {
    AGV_PLUGIN_NAMES+=("$1")
    AGV_PLUGIN_DESC["$1"]="$2"
}

AGV_WORK_DIR=""
agv_workdir() {
    [[ -z "${AGV_WORK_DIR}" ]] && AGV_WORK_DIR="$(mktemp -d)"
    printf '%s' "${AGV_WORK_DIR}"
}

agv_cleanup() {
    [[ -n "${AGV_WORK_DIR}" && -d "${AGV_WORK_DIR}" ]] && rm -rf "${AGV_WORK_DIR}"
}

trap agv_cleanup EXIT
