#!/usr/bin/env bash
# ╔══════════════════════════════════════════╗
# ║   dps installer                          ║
# ║   curl -fsSL <url>/install.sh | bash        ║
# ╚══════════════════════════════════════════╝

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/Ltomxd/docker-pretty-status/main"
INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_NAME="dps"

GRN="\033[0;92m"; RED="\033[0;91m"; CYN="\033[0;96m"
WHT="\033[0;97m"; DIM="\033[2m"; B="\033[1m"; R="\033[0m"

info()    { printf '%b  ➜  %s%b\n' "${CYN}" "$*" "${R}"; }
success() { printf '%b  ✔  %s%b\n' "${GRN}" "$*" "${R}"; }
error()   { printf '%b  ✖  %s%b\n' "${RED}" "$*" "${R}" >&2; exit 1; }

echo ""
printf '%b  🐳  dps — Docker Pretty Status — Installer%b\n\n' "${B}${WHT}" "${R}"

# ── Verificar dependencias ──────────────────────
for dep in docker curl bash tput; do
  command -v "$dep" >/dev/null 2>&1 || error "Required: '${dep}' not found in PATH"
done

BASH_VERSION_MAJOR="${BASH_VERSINFO[0]}"
(( BASH_VERSION_MAJOR < 4 )) && error "bash 4+ required (found ${BASH_VERSION})"

# ── Crear directorio ────────────────────────────
info "Installing to ${INSTALL_DIR}/${SCRIPT_NAME}"
mkdir -p "$INSTALL_DIR"

# ── Descargar script ────────────────────────────
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

if ! curl -fsSL "${REPO_RAW}/dps.sh" -o "$TMP"; then
  error "Download failed. Check your internet connection."
fi

chmod +x "$TMP"
mv "$TMP" "${INSTALL_DIR}/${SCRIPT_NAME}"

success "Downloaded dps v$(${INSTALL_DIR}/${SCRIPT_NAME} --version 2>/dev/null | awk '{print $2}' || echo '?')"

# ── Agregar al PATH si hace falta ───────────────
add_to_path() {
  local rc_file="$1"
  local export_line="export PATH=\"${INSTALL_DIR}:\$PATH\""
  if [[ -f "$rc_file" ]] && ! grep -qF "$INSTALL_DIR" "$rc_file"; then
    echo "" >> "$rc_file"
    echo "# dps — Docker Pretty Status" >> "$rc_file"
    echo "$export_line" >> "$rc_file"
    success "Added PATH to ${rc_file}"
  fi
}

if ! echo "$PATH" | grep -qF "$INSTALL_DIR"; then
  info "Adding ${INSTALL_DIR} to PATH..."
  add_to_path "${HOME}/.bashrc"
  add_to_path "${HOME}/.zshrc"
  echo ""
  printf '%b  ⚠  Reload your shell:%b  source ~/.bashrc\n\n' "${DIM}" "${R}"
fi

# ── Listo ───────────────────────────────────────
echo ""
printf '%b  ✔  Installation complete!%b\n\n' "${GRN}${B}" "${R}"
printf '  Run:  %bdps%b            → show table\n'       "${B}" "${R}"
printf '  Run:  %bdps -i%b         → interactive TUI\n'  "${B}" "${R}"
printf '  Run:  %bdps watch%b      → live auto-refresh\n' "${B}" "${R}"
printf '  Run:  %bdps --help%b     → all options\n\n'    "${B}" "${R}"
