#!/usr/bin/env bash

set -e

SRC_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGV_INSTALL_HOME="${AGV_INSTALL_HOME:-${HOME}}"
DEST_DIR="${AGV_INSTALL_HOME}/.local/share/agv"
BIN_DIR="${AGV_INSTALL_HOME}/.local/bin"

mkdir -p "${DEST_DIR}" "${BIN_DIR}"
cp -R "${SRC_DIR}/agv" "${SRC_DIR}/lib" "${SRC_DIR}/plugins" "${DEST_DIR}/"
chmod +x "${DEST_DIR}/agv"
ln -sf "${DEST_DIR}/agv" "${BIN_DIR}/agv"

printf 'agv instalado em %s\n' "${DEST_DIR}"

if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
    printf 'Aviso: %s não está no PATH.\n' "${BIN_DIR}" >&2
    printf 'Adicione a seguinte linha à configuração do seu shell:\n' >&2
    printf '  export PATH="%s:$PATH"\n' "${BIN_DIR}" >&2
else
    printf 'Execute "agv help" para começar.\n'
fi
