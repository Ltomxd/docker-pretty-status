#!/usr/bin/env bash
# ╔══════════════════════════════════════════════╗
# ║   dps — Docker Pretty Status  v1.0.0        ║
# ║   github.com/Ltomxd/docker-pretty-status  ║
# ╚══════════════════════════════════════════════╝

VERSION="1.0.0"
CONFIG_DIR="${HOME}/.config/dps"
CONFIG_FILE="${CONFIG_DIR}/dps.conf"

# ─────────────────────────────────────────────────
#  COLORES
# ─────────────────────────────────────────────────
R="\033[0m"; B="\033[1m"; DIM="\033[2m"
GRN="\033[0;92m"; RED="\033[0;91m"; YLW="\033[0;93m"
CYN="\033[0;96m"; WHT="\033[0;97m"
BG_HDR="\033[48;5;17m"
BG_SEL="\033[48;5;238m"

# ─────────────────────────────────────────────────
#  CARACTERES DE CAJA
# ─────────────────────────────────────────────────
HH="═"; V="║"
TL="╔"; TR="╗"; BL="╚"; BR="╝"
ML="╠"; MR="╣"; MT="╦"; MB="╩"; MMID="╬"
SL="╟"; SR="╢"; SS="─"; SM="┼"

# ─────────────────────────────────────────────────
#  CONFIG & PRIMER USO
# ─────────────────────────────────────────────────
init_config() {
  mkdir -p "$CONFIG_DIR"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    clear
    echo -e "\n${B}${CYN}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║  🐳  dps — Docker Pretty Status      ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${R}"
    echo -e "  Choose your language / Elige tu idioma:\n"
    echo -e "    ${B}[1]${R}  🇺🇸  English"
    echo -e "    ${B}[2]${R}  🇪🇸  Español\n"
    while true; do
      read -rp "  → " choice
      case "$choice" in
        1) echo "LANG_DPS=en" > "$CONFIG_FILE"; break ;;
        2) echo "LANG_DPS=es" > "$CONFIG_FILE"; break ;;
        *) echo -e "  ${RED}⚠  Type 1 or 2.${R}" ;;
      esac
    done
    echo -e "\n  ${GRN}✔  Config saved → ${CONFIG_FILE}${R}\n"
    sleep 1
  fi
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
}

# ─────────────────────────────────────────────────
#  i18n
# ─────────────────────────────────────────────────
load_strings() {
  if [[ "${LANG_DPS:-en}" == "es" ]]; then
    T_TITLE="Contenedores Docker"
    T_TOTAL="total"; T_UP="corriendo"; T_DOWN="detenidos"
    T_H_ID="🆔 ID";    T_H_NAME="📛 NOMBRE"; T_H_IMG="🖼️  IMAGEN"
    T_H_AGE="⏱️  HACE"; T_H_STAT="🔋 ESTADO"; T_H_CPU="💻 CPU"
    T_H_MEM="🧠 MEM";  T_H_PORT="📡 PUERTOS"
    T_HEALTHY="saludable"; T_RUNNING="corriendo"; T_STOPPED="detenido"
    T_EXITED="terminado";  T_PAUSED="pausado";    T_RESTARTING="reiniciando"
    T_UNKNOWN="desconocido"
    T_EMPTY="📭  No hay contenedores."
    T_WATCH_HINT="Ctrl+C para salir"
    T_YES_CHAR="s"
    T_CONFIRM_STOP="  ¿Detener '%s'? [s/N]: "
    T_CONFIRM_RESTART="  ¿Reiniciar '%s'? [s/N]: "
    T_CONFIRM_DELETE="  ¿Eliminar '%s'? (forzado) [s/N]: "
    T_CONFIRM_CLEAN="  ¿Eliminar contenedores parados e imágenes huérfanas? [s/N]: "
    T_KEYS_LINE="  ${DIM}↑↓ navegar   l logs   s detener   r reiniciar   d eliminar   c limpiar   w refrescar   q salir${R}"
    T_SELECTED="  Seleccionado"
    T_CLEANING="🧹 Limpiando..."
    T_DONE="✔  Listo"
    T_NO_STATS="(stats no disponibles)"
  else
    T_TITLE="Docker Containers"
    T_TOTAL="total"; T_UP="running"; T_DOWN="stopped"
    T_H_ID="🆔 ID";    T_H_NAME="📛 NAME"; T_H_IMG="🖼️  IMAGE"
    T_H_AGE="⏱️  AGE";  T_H_STAT="🔋 STATUS"; T_H_CPU="💻 CPU"
    T_H_MEM="🧠 MEM";  T_H_PORT="📡 PORTS"
    T_HEALTHY="healthy";     T_RUNNING="running";    T_STOPPED="stopped"
    T_EXITED="exited";       T_PAUSED="paused";      T_RESTARTING="restarting"
    T_UNKNOWN="unknown"
    T_EMPTY="📭  No containers found."
    T_WATCH_HINT="Ctrl+C to exit"
    T_YES_CHAR="y"
    T_CONFIRM_STOP="  Stop '%s'? [y/N]: "
    T_CONFIRM_RESTART="  Restart '%s'? [y/N]: "
    T_CONFIRM_DELETE="  Delete '%s'? (force) [y/N]: "
    T_CONFIRM_CLEAN="  Remove stopped containers & orphan images? [y/N]: "
    T_KEYS_LINE="  ${DIM}↑↓ navigate   l logs   s stop   r restart   d delete   c clean   w refresh   q quit${R}"
    T_SELECTED="  Selected"
    T_CLEANING="🧹 Cleaning..."
    T_DONE="✔  Done"
    T_NO_STATS="(stats unavailable)"
  fi
}

# ─────────────────────────────────────────────────
#  UTILIDADES DE TEXTO
# ─────────────────────────────────────────────────
strip_ansi() { printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g'; }
vlen()       { local s; s=$(strip_ansi "$1"); echo "${#s}"; }

trunc() {
  local raw; raw=$(strip_ansi "$1")
  local len=$2
  if (( ${#raw} > len )); then
    printf '%s' "${raw:0:$((len-1))}…"
  else
    printf "%-${len}s" "$raw"
  fi
}

pad_ansi() {
  # Pad a string that may contain ANSI codes to visible width $2
  local str="$1" len=$2
  local vis; vis=$(vlen "$str")
  local pad=$(( len - vis ))
  (( pad < 0 )) && pad=0
  printf '%b%s' "$str" "$(printf '%*s' $pad '')"
}

# ─────────────────────────────────────────────────
#  LÍNEAS DE TABLA
# ─────────────────────────────────────────────────
hline() {
  # hline LEFT MID SEP RIGHT w1 w2 ...
  local L=$1 MC=$2 SC=$3 RR=$4; shift 4
  local line="$L" first=1
  for w in "$@"; do
    [[ $first -eq 0 ]] && line+="$MC"
    line+=$(printf "${SC}%.0s" $(seq 1 $((w+2))))
    first=0
  done
  printf '%b%s%s%b\n' "${CYN}" "${line}" "${RR}" "${R}"
}

thin_hline() {
  # Thin separator between rows
  local line="$SL" first=1
  for w in "$@"; do
    [[ $first -eq 0 ]] && line+="$SM"
    line+=$(printf "${SS}%.0s" $(seq 1 $((w+2))))
    first=0
  done
  printf '%b%s%s%b\n' "${DIM}${CYN}" "${line}" "${SR}" "${R}"
}

# ─────────────────────────────────────────────────
#  FORMATO DE ESTADO
# ─────────────────────────────────────────────────
status_fmt() {
  local s="$1"
  if   [[ "$s" == *"Up"* && "$s" == *"healthy"* ]]; then printf '%b' "🟢${GRN} ${T_HEALTHY}${R}"
  elif [[ "$s" == *"Up"*                         ]]; then printf '%b' "🚀${GRN} ${T_RUNNING}${R}"
  elif [[ "$s" == *"Exited (0)"*                 ]]; then printf '%b' "⚪${DIM} ${T_STOPPED}${R}"
  elif [[ "$s" == *"Exited"*                     ]]; then printf '%b' "🔴${RED} ${T_EXITED}${R}"
  elif [[ "$s" == *"Paused"*                     ]]; then printf '%b' "⏸️ ${YLW} ${T_PAUSED}${R}"
  elif [[ "$s" == *"Restarting"*                 ]]; then printf '%b' "🔄${YLW} ${T_RESTARTING}${R}"
  else                                                    printf '%b' "❓${DIM} ${T_UNKNOWN}${R}"; fi
}

row_color() {
  local s="$1"
  if   [[ "$s" == *"Up"*         ]]; then printf '%b' "${WHT}"
  elif [[ "$s" == *"Exited (0)"* ]]; then printf '%b' "${DIM}"
  else                                    printf '%b' "${RED}"; fi
}

clean_ports() {
  local p="$1"
  [[ -z "$p" || "$p" == " " ]] && echo "—" && return
  printf '%s' "$p" \
    | tr ',' '\n' \
    | grep -v '\[::\]' \
    | sed 's/0\.0\.0\.0://g; s|/tcp||g; s|/udp||g' \
    | sort -u \
    | paste -sd ', '
}

# ─────────────────────────────────────────────────
#  OBTENER DATOS
# ─────────────────────────────────────────────────
FILTER_RUNNING=0
FILTER_NAME=""
FILTER_IMAGE=""
SHOW_STATS=1

get_containers() {
  local fmt="{{.ID}}|{{.Names}}|{{.Image}}|{{.RunningFor}}|{{.Status}}|{{.Ports}}"
  local args=()
  [[ $FILTER_RUNNING -eq 1 ]] && args+=(--filter "status=running")
  [[ -n "$FILTER_NAME"  ]] && args+=(--filter "name=${FILTER_NAME}")
  [[ -n "$FILTER_IMAGE" ]] && args+=(--filter "ancestor=${FILTER_IMAGE}")
  docker ps -a "${args[@]}" --format "$fmt" 2>/dev/null || true
}

declare -A STATS_CPU=() STATS_MEM=()

fetch_stats() {
  STATS_CPU=(); STATS_MEM=()
  local raw
  raw=$(docker stats --no-stream \
    --format "{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}" 2>/dev/null) || return 0
  while IFS='|' read -r name cpu mem; do
    [[ -z "$name" ]] && continue
    STATS_CPU["$name"]="$cpu"
    STATS_MEM["$name"]=$(printf '%s' "$mem" | awk '{print $1}')
  done <<< "$raw"
}

# ─────────────────────────────────────────────────
#  CALCULAR ANCHOS
# ─────────────────────────────────────────────────
W_ID=0; W_NAME=0; W_IMG=0; W_AGE=0
W_STAT=0; W_CPU=0; W_MEM=0; W_PORT=0

calc_widths() {
  local data="$1"
  W_ID=$(vlen "$T_H_ID");   W_NAME=$(vlen "$T_H_NAME")
  W_IMG=$(vlen "$T_H_IMG"); W_AGE=$(vlen "$T_H_AGE")
  W_STAT=14;                W_CPU=$(vlen "$T_H_CPU")
  W_MEM=$(vlen "$T_H_MEM"); W_PORT=$(vlen "$T_H_PORT")

  while IFS='|' read -r id name image age status ports; do
    local pc; pc=$(clean_ports "$ports")
    local cpu="${STATS_CPU[$name]:-}"; local mem="${STATS_MEM[$name]:-}"
    (( ${#id}    > W_ID   )) && W_ID=${#id}
    (( ${#name}  > W_NAME )) && W_NAME=${#name}
    (( ${#image} > W_IMG  )) && W_IMG=${#image}
    (( ${#age}   > W_AGE  )) && W_AGE=${#age}
    (( ${#pc}    > W_PORT )) && W_PORT=${#pc}
    (( ${#cpu}   > W_CPU  )) && W_CPU=${#cpu}
    (( ${#mem}   > W_MEM  )) && W_MEM=${#mem}
  done <<< "$data"

  local TERM_W; TERM_W=$(tput cols 2>/dev/null || echo 120)
  # 8 cols → 9 borders + 16 padding spaces
  local AVAIL=$(( TERM_W - 9 - 16 ))

  local MAX_ID=12  MAX_NAME=22 MAX_IMG=28 MAX_AGE=14
  local MAX_STAT=14 MAX_CPU=9 MAX_MEM=12 MAX_PORT=32
  local MIN_ID=6   MIN_NAME=8  MIN_IMG=10  MIN_AGE=8
  local MIN_STAT=12 MIN_CPU=5  MIN_MEM=6   MIN_PORT=6

  _clamp() { local v=$1 mn=$2 mx=$3; (( v<mn ))&&v=$mn; (( v>mx ))&&v=$mx; echo $v; }
  W_ID=$(_clamp   $W_ID   $MIN_ID   $MAX_ID  )
  W_NAME=$(_clamp $W_NAME $MIN_NAME $MAX_NAME)
  W_IMG=$(_clamp  $W_IMG  $MIN_IMG  $MAX_IMG )
  W_AGE=$(_clamp  $W_AGE  $MIN_AGE  $MAX_AGE )
  W_STAT=$(_clamp $W_STAT $MIN_STAT $MAX_STAT)
  W_CPU=$(_clamp  $W_CPU  $MIN_CPU  $MAX_CPU )
  W_MEM=$(_clamp  $W_MEM  $MIN_MEM  $MAX_MEM )
  W_PORT=$(_clamp $W_PORT $MIN_PORT $MAX_PORT)

  local TOTAL=$(( W_ID+W_NAME+W_IMG+W_AGE+W_STAT+W_CPU+W_MEM+W_PORT ))

  if (( TOTAL > AVAIL )); then
    local EXCESS=$(( TOTAL - AVAIL ))
    # Reduce las más anchas/menos críticas primero
    for col in W_PORT W_IMG W_NAME W_AGE W_ID W_CPU W_MEM W_STAT; do
      declare -n _ref=$col
      local _min
      case $col in
        W_ID)   _min=$MIN_ID;;   W_NAME) _min=$MIN_NAME;; W_IMG)  _min=$MIN_IMG;;
        W_AGE)  _min=$MIN_AGE;;  W_STAT) _min=$MIN_STAT;; W_CPU)  _min=$MIN_CPU;;
        W_MEM)  _min=$MIN_MEM;;  W_PORT) _min=$MIN_PORT;; *)       _min=6;;
      esac
      local _cut=$(( _ref - _min ))
      if (( _cut >= EXCESS )); then _ref=$(( _ref - EXCESS )); EXCESS=0; break
      else _ref=$_min; EXCESS=$(( EXCESS - _cut )); fi
    done
  fi
}

# ─────────────────────────────────────────────────
#  RENDER TABLA
# ─────────────────────────────────────────────────
render_table() {
  local data="$1"
  local selected="${2:--1}"
  local WW=($W_ID $W_NAME $W_IMG $W_AGE $W_STAT $W_CPU $W_MEM $W_PORT)
  local HEADERS=("$T_H_ID" "$T_H_NAME" "$T_H_IMG" "$T_H_AGE" \
                 "$T_H_STAT" "$T_H_CPU" "$T_H_MEM" "$T_H_PORT")

  local TOTAL RUNNING STOPPED
  TOTAL=$(printf '%s\n' "$data" | wc -l | tr -d ' ')
  RUNNING=$(printf '%s\n' "$data" | grep -c "Up" 2>/dev/null || echo 0)
  STOPPED=$(( TOTAL - RUNNING ))

  # Header banner
  printf '%b  🐳  %s  ·  📦 %s %s  🟢 %s %s  🔴 %s %s  ·  %s  %b\n' \
    "${BG_HDR}${B}${WHT}" "$T_TITLE" \
    "$TOTAL" "$T_TOTAL" "$RUNNING" "$T_UP" "$STOPPED" "$T_DOWN" \
    "$(date '+%H:%M:%S')" "${R}"
  echo ""

  # Borde superior
  hline "$TL" "$MT" "$HH" "$TR" "${WW[@]}"

  # Cabecera
  printf '%b%s%b' "${CYN}" "${V}" "${R}"
  for i in "${!HEADERS[@]}"; do
    printf ' %b%b%s%b %b%s%b' \
      "${B}" "${CYN}" "$(trunc "${HEADERS[$i]}" ${WW[$i]})" "${R}" \
      "${CYN}" "${V}" "${R}"
  done
  echo ""

  # Separador doble
  hline "$ML" "$MMID" "$HH" "$MR" "${WW[@]}"

  # Filas
  local idx=0 first=1
  while IFS='|' read -r id name image age status ports; do
    [[ $first -eq 0 ]] && thin_hline "${WW[@]}"

    local stat_d port_d cpu_d mem_d RC SEL_START SEL_END
    stat_d=$(status_fmt "$status")
    port_d=$(clean_ports "$ports")
    cpu_d="${STATS_CPU[$name]:-—}"
    mem_d="${STATS_MEM[$name]:-—}"
    RC=$(row_color "$status")

    if (( idx == selected )); then
      SEL_START="${BG_SEL}"
      SEL_END="${R}"
    else
      SEL_START=""
      SEL_END=""
    fi

    printf '%b%s%b' "${CYN}" "${V}" "${R}"
    printf '%b%b %s %b%b%s%b' \
      "$SEL_START" "$RC" "$(trunc "$id"     $W_ID  )" "$SEL_END" \
      "${CYN}" "${V}" "${R}"
    printf '%b%b %s %b%b%s%b' \
      "$SEL_START" "$RC" "$(trunc "$name"   $W_NAME)" "$SEL_END" \
      "${CYN}" "${V}" "${R}"
    printf '%b%b %s %b%b%s%b' \
      "$SEL_START" "$RC" "$(trunc "$image"  $W_IMG )" "$SEL_END" \
      "${CYN}" "${V}" "${R}"
    printf '%b%b %s %b%b%s%b' \
      "$SEL_START" "$RC" "$(trunc "$age"    $W_AGE )" "$SEL_END" \
      "${CYN}" "${V}" "${R}"
    printf '%b %s %b%b%s%b' \
      "$SEL_START" "$(pad_ansi "$stat_d" $W_STAT)" "$SEL_END" \
      "${CYN}" "${V}" "${R}"
    printf '%b%b %s %b%b%s%b' \
      "$SEL_START" "${GRN}" "$(trunc "$cpu_d"  $W_CPU )" "$SEL_END" \
      "${CYN}" "${V}" "${R}"
    printf '%b%b %s %b%b%s%b' \
      "$SEL_START" "${YLW}" "$(trunc "$mem_d"  $W_MEM )" "$SEL_END" \
      "${CYN}" "${V}" "${R}"
    printf '%b%b %s %b%b%s%b\n' \
      "$SEL_START" "$RC" "$(trunc "$port_d" $W_PORT)" "$SEL_END" \
      "${CYN}" "${V}" "${R}"

    (( idx++ )) || true
    first=0
  done <<< "$data"

  # Borde inferior
  hline "$BL" "$MB" "$HH" "$BR" "${WW[@]}"
}

# ─────────────────────────────────────────────────
#  MODO: UNA VEZ
# ─────────────────────────────────────────────────
mode_once() {
  local data; data=$(get_containers)
  if [[ -z "$data" ]]; then
    echo -e "\n  ${YLW}${T_EMPTY}${R}\n"; exit 0
  fi
  [[ $SHOW_STATS -eq 1 ]] && fetch_stats
  calc_widths "$data"
  echo ""
  render_table "$data" -1
  echo ""
}

# ─────────────────────────────────────────────────
#  MODO: WATCH (auto-refresh)
# ─────────────────────────────────────────────────
mode_watch() {
  local interval="${1:-2}"
  trap 'tput cnorm; echo ""; exit 0' INT TERM
  tput civis
  while true; do
    local data; data=$(get_containers)
    [[ $SHOW_STATS -eq 1 ]] && fetch_stats
    [[ -n "$data" ]] && calc_widths "$data"
    clear
    echo ""
    if [[ -z "$data" ]]; then
      echo -e "  ${YLW}${T_EMPTY}${R}"
    else
      render_table "$data" -1
    fi
    printf '\n  %b🔄  %s · refresh %ss%b\n' \
      "${DIM}" "$T_WATCH_HINT" "$interval" "${R}"
    sleep "$interval"
  done
  tput cnorm
}

# ─────────────────────────────────────────────────
#  MODO: INTERACTIVO (TUI con teclado)
# ─────────────────────────────────────────────────
read_key() {
  local key rest
  IFS= read -rsn1 key
  if [[ "$key" == $'\x1b' ]]; then
    read -rsn2 -t 0.15 rest 2>/dev/null || true
    key+="$rest"
  fi
  printf '%s' "$key"
}

mode_interactive() {
  trap '_tui_cleanup; exit 0' INT TERM

  _tui_cleanup() { tput cnorm; tput rmcup 2>/dev/null || true; }

  tput smcup 2>/dev/null || true
  tput civis

  local selected=0
  local data=""
  local -a names=()

  _refresh() {
    data=$(get_containers)
    names=()
    [[ $SHOW_STATS -eq 1 ]] && fetch_stats
    if [[ -n "$data" ]]; then
      calc_widths "$data"
      while IFS='|' read -r _ name _rest; do
        names+=("$name")
      done <<< "$data"
    fi
    local count=${#names[@]}
    (( count == 0 )) && selected=0
    (( selected >= count && count > 0 )) && selected=$(( count - 1 ))
    (( selected < 0 )) && selected=0
  }

  _draw() {
    tput cup 0 0
    clear
    echo ""
    if [[ -z "$data" || ${#names[@]} -eq 0 ]]; then
      echo -e "  ${YLW}${T_EMPTY}${R}"
    else
      render_table "$data" "$selected"
      echo -e "\n${T_KEYS_LINE}"
      printf '\n  %b%s:%b %b%s%b\n' \
        "${DIM}" "$T_SELECTED" "${R}" \
        "${B}${WHT}" "${names[$selected]:-—}" "${R}"
    fi
  }

  _confirm() {
    # Pregunta al final de la pantalla y devuelve 0 si acepta
    local prompt="$1"
    tput cup $(( $(tput lines) - 2 )) 0
    printf '%b' "${R}"
    printf "$prompt"
    tput cnorm
    local ans; read -r ans
    tput civis
    [[ "${ans,,}" == "${T_YES_CHAR}" ]]
  }

  _refresh
  _draw

  while true; do
    local key; key=$(read_key)
    local count=${#names[@]}

    case "$key" in
      # ── Navegación ──────────────────────
      $'\x1b[A'|k) (( count > 0 && selected > 0 )) && (( selected-- )) ;;
      $'\x1b[B'|j) (( count > 0 && selected < count-1 )) && (( selected++ )) ;;

      # ── Logs ────────────────────────────
      l|L)
        local cn="${names[$selected]:-}"
        [[ -n "$cn" ]] && {
          tput cnorm; tput rmcup 2>/dev/null || true
          docker logs --tail 80 -f "$cn"
          tput smcup 2>/dev/null || true; tput civis
          _refresh
        } ;;

      # ── Stop ────────────────────────────
      s|S)
        local cn="${names[$selected]:-}"
        [[ -n "$cn" ]] && {
          if _confirm "$(printf "$T_CONFIRM_STOP" "$cn")"; then
            docker stop "$cn" >/dev/null 2>&1 || true
          fi
          _refresh
        } ;;

      # ── Restart ─────────────────────────
      r|R)
        local cn="${names[$selected]:-}"
        [[ -n "$cn" ]] && {
          if _confirm "$(printf "$T_CONFIRM_RESTART" "$cn")"; then
            docker restart "$cn" >/dev/null 2>&1 || true
          fi
          _refresh
        } ;;

      # ── Delete ──────────────────────────
      d|D)
        local cn="${names[$selected]:-}"
        [[ -n "$cn" ]] && {
          if _confirm "$(printf "$T_CONFIRM_DELETE" "$cn")"; then
            docker rm -f "$cn" >/dev/null 2>&1 || true
          fi
          _refresh
          (( selected > 0 && selected >= ${#names[@]} )) && (( selected-- )) || true
        } ;;

      # ── Clean ───────────────────────────
      c|C)
        if _confirm "$T_CONFIRM_CLEAN"; then
          docker container prune -f >/dev/null 2>&1 || true
          docker image prune -f     >/dev/null 2>&1 || true
        fi
        _refresh ;;

      # ── Refresh manual ──────────────────
      w|W) _refresh ;;

      # ── Filtros toggle ──────────────────
      f|F)
        if (( FILTER_RUNNING == 0 )); then FILTER_RUNNING=1
        else FILTER_RUNNING=0; fi
        _refresh ;;

      # ── Salir ───────────────────────────
      q|Q) break ;;
    esac

    _draw
  done

  _tui_cleanup
}

# ─────────────────────────────────────────────────
#  SUBCOMANDOS DIRECTOS
# ─────────────────────────────────────────────────
cmd_logs()    { docker logs --tail 80 -f "$1"; }
cmd_stop()    { docker stop "$1"    && printf '%b✔  Stopped %s%b\n'    "${GRN}" "$1" "${R}"; }
cmd_restart() { docker restart "$1" && printf '%b✔  Restarted %s%b\n'  "${GRN}" "$1" "${R}"; }
cmd_clean() {
  printf '%b%s%b\n' "${YLW}" "$T_CLEANING" "${R}"
  docker container prune -f
  docker image prune -f
  printf '%b%s%b\n' "${GRN}" "$T_DONE" "${R}"
}

# ─────────────────────────────────────────────────
#  AYUDA
# ─────────────────────────────────────────────────
usage() {
  printf '%b\n' "
${B}${CYN}🐳 dps v${VERSION}${R} — Docker Pretty Status

${B}Uso / Usage:${R}
  dps                       Mostrar tabla una vez
  dps watch [secs]          Auto-refresh (default: 2s)
  dps -i / interactive      Modo TUI interactivo
  dps logs <nombre>         Ver logs del contenedor
  dps stop <nombre>         Detener contenedor
  dps restart <nombre>      Reiniciar contenedor
  dps clean                 Limpiar parados + imágenes huérfanas
  dps config                Reconfigurar idioma
  dps --version

${B}Filtros:${R}
  --running                 Solo contenedores corriendo
  --name <patrón>           Filtrar por nombre
  --image <imagen>          Filtrar por imagen
  --no-stats                Sin columnas CPU/MEM (más rápido)

${B}Teclas modo interactivo:${R}
  ↑ ↓  Navegar    l  Logs    s  Stop    r  Restart
  d    Delete     c  Clean   f  Toggle running   w  Refresh   q  Quit
"
}

# ─────────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────────
main() {
  init_config
  load_strings

  local MODE="once"
  local WATCH_INT=2
  local SUBCMD=""
  local SUBCMD_ARG=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      watch)
        MODE="watch"
        [[ $# -gt 1 && "$2" =~ ^[0-9]+$ ]] && { WATCH_INT=$2; shift; }
        ;;
      interactive|-i)
        MODE="interactive"
        ;;
      logs)
        SUBCMD="logs"
        [[ $# -gt 1 ]] && { SUBCMD_ARG=$2; shift; }
        ;;
      stop)
        SUBCMD="stop"
        [[ $# -gt 1 ]] && { SUBCMD_ARG=$2; shift; }
        ;;
      restart)
        SUBCMD="restart"
        [[ $# -gt 1 ]] && { SUBCMD_ARG=$2; shift; }
        ;;
      clean)        SUBCMD="clean" ;;
      config)       rm -f "$CONFIG_FILE"; init_config; load_strings; return ;;
      --running)    FILTER_RUNNING=1 ;;
      --name)       [[ $# -gt 1 ]] && { FILTER_NAME=$2; shift; } ;;
      --image)      [[ $# -gt 1 ]] && { FILTER_IMAGE=$2; shift; } ;;
      --no-stats)   SHOW_STATS=0 ;;
      --version|-v) echo "dps v${VERSION}"; exit 0 ;;
      --help|-h)    usage; exit 0 ;;
      *)
        printf '%b⚠  Unknown option: %s%b\n' "${RED}" "$1" "${R}" >&2
        usage; exit 1
        ;;
    esac
    shift
  done

  if [[ -n "$SUBCMD" ]]; then
    case "$SUBCMD" in
      logs)    cmd_logs    "$SUBCMD_ARG" ;;
      stop)    cmd_stop    "$SUBCMD_ARG" ;;
      restart) cmd_restart "$SUBCMD_ARG" ;;
      clean)   cmd_clean ;;
    esac
    return
  fi

  case "$MODE" in
    once)        mode_once ;;
    watch)       mode_watch "$WATCH_INT" ;;
    interactive) mode_interactive ;;
  esac
}

main "$@"
