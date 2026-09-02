#!/usr/bin/env bash

register_plugin ide "Antigravity IDE (pacote RPM/DEB)"

readonly IDE_PACKAGE_NAME="antigravity-ide"
readonly IDE_LEGACY_PACKAGE_NAME="antigravity"
readonly IDE_PACKER_REPO="https://github.com/vittico/packaged-gravity.git"
readonly IDE_DOWNLOAD_PAGE="https://antigravity.google/download"
readonly IDE_FALLBACK_URL="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-x64/Antigravity%20IDE.tar.gz"

_ide_pkg_family() {
    if command -v dnf >/dev/null 2>&1; then
        printf 'rpm'
    elif command -v apt-get >/dev/null 2>&1; then
        printf 'deb'
    else
        c_err "Distribuição não suportada: dnf ou apt-get não foi encontrado."
        return 1
    fi
}

_ide_check_deps() {
    local family="$1"
    local missing=()
    local command_name

    require_sudo || return 1

    for command_name in git python3 curl; do
        command -v "${command_name}" >/dev/null 2>&1 || missing+=("${command_name}")
    done

    case "${family}" in
        rpm)
            command -v rpmbuild >/dev/null 2>&1 || missing+=("rpm-build")
            if (( ${#missing[@]} > 0 )); then
                c_info "Instalando dependências: ${missing[*]}"
                ${SUDO} dnf install -y "${missing[@]}" || return 1
            fi
            ;;
        deb)
            command -v dpkg-deb >/dev/null 2>&1 || missing+=("dpkg")
            if (( ${#missing[@]} > 0 )); then
                c_info "Atualizando o índice de pacotes..."
                ${SUDO} apt-get update -qq || return 1
                c_info "Instalando dependências: ${missing[*]}"
                ${SUDO} apt-get install -y "${missing[@]}" || return 1
            fi
            ;;
        *)
            c_err "Família de pacotes desconhecida: ${family}"
            return 1
            ;;
    esac
}

_ide_query_version() {
    local family="$1"

    case "${family}" in
        rpm)
            rpm -q "${IDE_PACKAGE_NAME}" >/dev/null 2>&1 || return 1
            rpm -q --qf '%{VERSION}' "${IDE_PACKAGE_NAME}" 2>/dev/null
            ;;
        deb)
            dpkg-query -W "${IDE_PACKAGE_NAME}" >/dev/null 2>&1 || return 1
            dpkg-query -W -f='${Version}' "${IDE_PACKAGE_NAME}" 2>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

_ide_legacy_version() {
    local family="$1"

    case "${family}" in
        rpm)
            rpm -q "${IDE_LEGACY_PACKAGE_NAME}" >/dev/null 2>&1 || return 1
            rpm -q --qf '%{VERSION}' "${IDE_LEGACY_PACKAGE_NAME}" 2>/dev/null
            ;;
        deb)
            dpkg-query -W "${IDE_LEGACY_PACKAGE_NAME}" >/dev/null 2>&1 || return 1
            dpkg-query -W -f='${Version}' "${IDE_LEGACY_PACKAGE_NAME}" 2>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

_ide_detect_latest_url() {
    local page
    local url
    local user_agent="Mozilla/5.0 (X11; Linux $(uname -m))"

    page="$(curl --compressed -A "${user_agent}" -fsSL "${IDE_DOWNLOAD_PAGE}" 2>/dev/null || true)"
    url="$(printf '%s' "${page}" \
        | grep -oE 'https://edgedl\.me\.gvt1\.com/[^"[:space:]]*/linux-x64/Antigravity%20IDE\.tar\.gz' \
        | head -n 1 || true)"

    if [[ -n "${url}" ]]; then
        printf '%s' "${url}"
    else
        c_warn "Não foi possível detectar a versão mais recente; usando a URL de fallback."
        printf '%s' "${IDE_FALLBACK_URL}"
    fi
}

_ide_version_from_url() {
    grep -oP '(?<=/stable/)[0-9]+\.[0-9]+\.[0-9]+(?=-[0-9]+/)' <<<"$1" | head -n 1
}

_ide_build_and_install() {
    local url="$1"
    local family
    local build_dir
    local tarball
    local packer_dir
    local dist_dir
    local package_file

    family="$(_ide_pkg_family)" || return 1
    _ide_check_deps "${family}" || return 1

    agv_workdir >/dev/null || return 1
    build_dir="${AGV_WORK_DIR}/ide"
    tarball="${build_dir}/Antigravity-IDE.tar.gz"
    packer_dir="${build_dir}/packaged-gravity"
    dist_dir="${build_dir}/dist"
    mkdir -p "${build_dir}" "${dist_dir}" || return 1

    c_info "Baixando o Antigravity IDE..."
    curl -fL "${url}" -o "${tarball}" || {
        c_err "Falha ao baixar o Antigravity IDE."
        return 1
    }

    c_info "Obtendo o empacotador..."
    git clone --depth 1 "${IDE_PACKER_REPO}" "${packer_dir}" || {
        c_err "Falha ao clonar packaged-gravity."
        return 1
    }

    c_info "Gerando o pacote ${family}..."
    (cd "${packer_dir}" && ./build.sh "${tarball}" --format "${family}" --outdir "${dist_dir}") || {
        c_err "Falha ao gerar o pacote do Antigravity IDE."
        return 1
    }

    package_file="$(find "${dist_dir}" -type f \( -name '*.rpm' -o -name '*.deb' \) -print -quit)"
    if [[ -z "${package_file}" ]]; then
        c_err "O empacotador não gerou um arquivo RPM ou DEB."
        return 1
    fi

    c_info "Instalando $(basename "${package_file}")..."
    case "${family}" in
        rpm)
            ${SUDO} dnf install -y "${package_file}" || return 1
            ;;
        deb)
            ${SUDO} apt-get install -y "${package_file}" || return 1
            ;;
    esac

    c_ok "Antigravity IDE instalado com sucesso."
}

ide_install() {
    local family
    local current_version
    local url

    family="$(_ide_pkg_family)" || return 1
    current_version="$(_ide_query_version "${family}" || true)"
    if [[ -n "${current_version}" ]]; then
        c_warn "Antigravity IDE ${current_version} já está instalado. Use 'agv update ide'."
        return 0
    fi

    url="$(_ide_detect_latest_url)" || return 1
    _ide_build_and_install "${url}"
}

ide_update() {
    local family
    local current_version
    local latest_version
    local url

    family="$(_ide_pkg_family)" || return 1
    current_version="$(_ide_query_version "${family}" || true)"
    if [[ -z "${current_version}" ]]; then
        c_info "Antigravity IDE ainda não está instalado; iniciando a instalação."
        ide_install
        return $?
    fi

    url="$(_ide_detect_latest_url)" || return 1
    latest_version="$(_ide_version_from_url "${url}" || true)"
    if [[ -z "${latest_version}" ]]; then
        c_err "Não foi possível extrair a versão da URL de download."
        return 1
    fi

    if [[ "${current_version}" == "${latest_version}" ]]; then
        c_ok "Antigravity IDE já está atualizado (${current_version})."
        return 0
    fi

    c_info "Atualizando o Antigravity IDE de ${current_version} para ${latest_version}..."
    _ide_build_and_install "${url}"
}

ide_status() {
    local family
    local current_version
    local legacy_version

    family="$(_ide_pkg_family)" || return 1
    current_version="$(_ide_query_version "${family}" || true)"
    legacy_version="$(_ide_legacy_version "${family}" || true)"

    if [[ -n "${current_version}" ]]; then
        c_ok "Antigravity IDE instalado: ${current_version}"
    else
        c_warn "Antigravity IDE não está instalado."
    fi

    if [[ -n "${legacy_version}" ]]; then
        c_warn "O pacote legado ${IDE_LEGACY_PACKAGE_NAME} (${legacy_version}) ainda está instalado."
        c_warn "Remova-o com 'agv remove-legacy ide'."
    fi
}

ide_uninstall() {
    local family

    family="$(_ide_pkg_family)" || return 1
    if ! _ide_query_version "${family}" >/dev/null; then
        c_warn "Antigravity IDE não está instalado."
        return 0
    fi

    require_sudo || return 1
    case "${family}" in
        rpm)
            ${SUDO} dnf remove -y "${IDE_PACKAGE_NAME}" || return 1
            ;;
        deb)
            ${SUDO} apt-get remove -y "${IDE_PACKAGE_NAME}" || return 1
            ;;
    esac
    c_ok "Antigravity IDE removido."
}

ide_remove_legacy() {
    local family
    local legacy_version

    family="$(_ide_pkg_family)" || return 1
    legacy_version="$(_ide_legacy_version "${family}" || true)"
    require_sudo || return 1

    case "${family}" in
        rpm)
            if [[ -n "${legacy_version}" ]]; then
                ${SUDO} dnf remove -y "${IDE_LEGACY_PACKAGE_NAME}" || return 1
            fi
            ${SUDO} rm -f /etc/yum.repos.d/antigravity.repo || return 1
            ;;
        deb)
            if [[ -n "${legacy_version}" ]]; then
                ${SUDO} apt-get remove -y "${IDE_LEGACY_PACKAGE_NAME}" || return 1
            fi
            ${SUDO} rm -f \
                /etc/apt/sources.list.d/antigravity.list \
                /etc/apt/keyrings/antigravity-repo-key.gpg || return 1
            ;;
    esac

    c_ok "Pacote e repositório legados removidos."
}
