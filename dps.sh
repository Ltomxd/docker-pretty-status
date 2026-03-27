#!/usr/bin/env bash
# ╔══════════════════════════════════════════════╗
# ║   dps — Docker Pretty Status  v1.1.0        ║
# ║   github.com/Ltomxd/docker-pretty-status    ║
# ╚══════════════════════════════════════════════╝

VERSION="1.1.0"
CONFIG_DIR="${HOME}/.config/dps"
CONFIG_FILE="${CONFIG_DIR}/dps.conf"

# ─── Colores ────────────────────────────────────
R="\033[0m"; B="\033[1m"; DIM="\033[2m"
GRN="\033[0;92m"; RED="\033[0;91m"; YLW="\033[0;93m"
CYN="\033[0;96m"; WHT="\033[0;97m"
BG_HDR="\033[48;5;17m"
BG_SEL="\033[48;5;238m"

# ─── Caja ───────────────────────────────────────
HH="═"; V="║"
TL="╔"; TR="╗"; BL="╚"; BR="╝"
ML="╠"; MR="╣"; MT="╦"; MB="╩"; MX="╬"
SL="╟"; SR="╢"; SS="─"; SM="┼"; STT="┬"; STB="┴"

# ─────────────────────────────────────────────────
#  ANCHO VISUAL (respeta emojis de 2 columnas)
# ─────────────────────────────────────────────────
# Quita secuencias ANSI y cuenta columnas reales
visual_len() {
  local s="$1"
  # Strip ANSI
  s="$(printf '%s' "$s" | sed 's/\x1b\[[0-9;]*m//g')"
  local len=0
  local i=0
  local total=${#s}
  while (( i < total )); do
    local byte="${s:$i:1}"
    local code
    code=$(printf '%d' "'$byte" 2>/dev/null || echo 0)
    if (( code < 0x80 )); then
      # ASCII
      (( len++ )); (( i++ ))
    elif (( code < 0xC0 )); then
      # Continuation byte — skip
      (( i++ ))
    elif (( code < 0xE0 )); then
      # 2-byte UTF-8
      local ch="${s:$i:2}"
      local cp
      cp=$(printf '%s' "$ch" | iconv -f UTF-8 -t UTF-32BE 2>/dev/null | od -An -tu4 | tr -d ' \n' || echo 0)
      (( len++ )); (( i+=2 ))
    elif (( code < 0xF0 )); then
      # 3-byte UTF-8 (CJK y emojis simples)
      local ch="${s:$i:3}"
      (( len+=2 )); (( i+=3 ))
    else
      # 4-byte UTF-8 (emojis compuestos)
      (( len+=2 )); (( i+=4 ))
    fi
  done
  echo $len
}

# Pad una cadena (con o sin ANSI) a ancho visual $2
pad_to() {
  local str="$1"
  local target=$2
  local vis
  vis=$(visual_len "$str")
  local pad=$(( target - vis ))
  (( pad < 0 )) && pad=0
  printf '%b%s' "$str" "$(printf '%*s' $pad '')"
}

# Truncar al ancho visual $2 (sin ANSI)
trunc_to() {
  local str
  str=$(printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g')
  local target=$2
  local result="" len=0 i=0 total=${#str}
  while (( i < total )); do
    local byte="${str:$i:1}"
    local code
    code=$(printf '%d' "'$byte" 2>/dev/null || echo 0)
    local w=1 bw=1
    if   (( code < 0x80 )); then w=1; bw=1
    elif (( code < 0xC0 )); then w=0; bw=1
    elif (( code < 0xE0 )); then w=1; bw=2
    elif (( code < 0xF0 )); then w=2; bw=3
    else                          w=2; bw=4; fi

    if (( len + w > target )); then
      result+="…"
      break
    fi
    result+="${str:$i:$bw}"
    (( len += w )); (( i += bw ))
  done
  # Pad restante
  local pad=$(( target - len ))
  (( ${#result} == 0 && pad > 0 )) && result="$(printf '%*s' $target '')"
  printf '%s%*s' "$result" "$pad" ''
}

# ─────────────────────────────────────────────────
#  CONFIG & PRIMER USO
# ─────────────────────────────────────────────────
init_config() {
  mkdir -p "$CONFIG_DIR"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    clear
    printf '\n%b  ╔══════════════════════════════════════╗\n' "${B}${CYN}"
    printf '  ║  dps  Docker Pretty Status v%s     ║\n' "$VERSION"
    printf '  ╚══════════════════════════════════════╝%b\n\n' "${R}"
    printf '  Choose your language / Elige tu idioma:\n\n'
    printf '    %b[1]%b  EN  English\n' "${B}" "${R}"
    printf '    %b[2]%b  ES  Espanol\n\n' "${B}" "${R}"
    while true; do
      read -rp "  -> " choice
      case "$choice" in
        1) echo "LANG_DPS=en" > "$CONFIG_FILE"; break ;;
        2) echo "LANG_DPS=es" > "$CONFIG_FILE"; break ;;
        *) printf '  %bType 1 or 2.%b\n' "${RED}" "${R}" ;;
      esac
    done
    printf '\n  %bConfig saved -> %s%b\n\n' "${GRN}" "$CONFIG_FILE" "${R}"
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
    T_H_ID="ID"; T_H_NAME="NOMBRE"; T_H_IMG="IMAGEN"
    T_H_AGE="HACE";  T_H_STAT="ESTADO"
    T_H_CPU="CPU";   T_H_MEM="MEM";  T_H_PORT="PUERTOS"
    T_HEALTHY="saludable"; T_RUNNING="corriendo"; T_STOPPED="detenido"
    T_EXITED="terminado";  T_PAUSED="pausado";    T_RESTARTING="reiniciando"
    T_UNKNOWN="desconocido"; T_EMPTY="No hay contenedores."
    T_WATCH_HINT="Ctrl+C para salir"
    T_YES_CHAR="s"
    T_CONFIRM_STOP="  Detener '%s'? [s/N]: "
    T_CONFIRM_RESTART="  Reiniciar '%s'? [s/N]: "
    T_CONFIRM_DELETE="  Eliminar '%s'? (forzado) [s/N]: "
    T_CONFIRM_CLEAN="  Eliminar contenedores parados e imagenes? [s/N]: "
    T_KEYS="  nav:arriba/abajo  l:logs  s:stop  r:restart  d:delete  c:clean  w:refresh  q:salir"
    T_SELECTED="Seleccionado"; T_CLEANING="Limpiando..."; T_DONE="Listo"
  else
    T_TITLE="Docker Containers"
    T_TOTAL="total"; T_UP="running"; T_DOWN="stopped"
    T_H_ID="ID"; T_H_NAME="NAME"; T_H_IMG="IMAGE"
    T_H_AGE="AGE";   T_H_STAT="STATUS"
    T_H_CPU="CPU";   T_H_MEM="MEM";  T_H_PORT="PORTS"
    T_HEALTHY="healthy";  T_RUNNING="running";    T_STOPPED="stopped"
    T_EXITED="exited";    T_PAUSED="paused";      T_RESTARTING="restarting"
    T_UNKNOWN="unknown";  T_EMPTY="No containers found."
    T_WATCH_HINT="Ctrl+C to exit"
    T_YES_CHAR="y"
    T_CONFIRM_STOP="  Stop '%s'? [y/N]: "
    T_CONFIRM_RESTART="  Restart '%s'? [y/N]: "
    T_CONFIRM_DELETE="  Delete '%s'? (force) [y/N]: "
    T_CONFIRM_CLEAN="  Remove stopped containers & orphan images? [y/N]: "
    T_KEYS="  nav:up/down  l:logs  s:stop  r:restart  d:delete  c:clean  w:refresh  q:quit"
    T_SELECTED="Selected"; T_CLEANING="Cleaning..."; T_DONE="Done"
  fi

  # Emojis separados — NO van dentro de los headers de la tabla
  E_ID="🆔"; E_NAME="📛"; E_IMG="🖼 "; E_AGE="⏱ "
  E_STAT="🔋"; E_CPU="💻"; E_MEM="🧠"; E_PORT="📡"
}

# ─────────────────────────────────────────────────
#  ESTADO Y COLORES
# ─────────────────────────────────────────────────
status_fmt() {
  local s="$1"
  if   [[ "$s" == *"Up"* && "$s" == *"healthy"* ]]; then printf '%b* %s%b' "${GRN}" "${T_HEALTHY}"  "${R}"
  elif [[ "$s" == *"Up"*                         ]]; then printf '%b> %s%b' "${GRN}" "${T_RUNNING}"  "${R}"
  elif [[ "$s" == *"Exited (0)"*                 ]]; then printf '%b- %s%b' "${DIM}" "${T_STOPPED}"  "${R}"
  elif [[ "$s" == *"Exited"*                     ]]; then printf '%b! %s%b' "${RED}" "${T_EXITED}"   "${R}"
  elif [[ "$s" == *"Paused"*                     ]]; then printf '%b~ %s%b' "${YLW}" "${T_PAUSED}"   "${R}"
  elif [[ "$s" == *"Restarting"*                 ]]; then printf '%b@ %s%b' "${YLW}" "${T_RESTARTING}" "${R}"
  else                                                    printf '%b? %s%b' "${DIM}" "${T_UNKNOWN}"  "${R}"; fi
}

row_color() {
  local s="$1"
  if   [[ "$s" == *"Up"*         ]]; then printf '%b' "${WHT}"
  elif [[ "$s" == *"Exited (0)"* ]]; then printf '%b' "${DIM}"
  else                                    printf '%b' "${RED}"; fi
}

clean_ports() {
  local p="$1"
  [[ -z "$p" || "$p" == " " ]] && echo "-" && return
  printf '%s' "$p" \
    | tr ',' '\n' \
    | grep -v '\[::\]' \
    | sed 's/0\.0\.0\.0://g; s|/tcp||g; s|/udp||g' \
    | sort -u \
    | paste -sd ' ' \
    | sed 's/  */ /g'
}

# ─────────────────────────────────────────────────
#  LÍNEAS DE TABLA
# ─────────────────────────────────────────────────
# hline LEFT MID_CROSS FILL RIGHT w1 w2 w3 ...
hline() {
  local L=$1 MC=$2 FC=$3 RR=$4; shift 4
  local line="$L" first=1
  for w in "$@"; do
    [[ $first -eq 0 ]] && line+="$MC"
    local seg; seg=$(printf "${FC}%.0s" $(seq 1 $((w+2))))
    line+="$seg"
    first=0
  done
  line+="$RR"
  printf '%b%s%b\n' "${CYN}" "$line" "${R}"
}

thin_hline() {
  local line="$SL" first=1
  for w in "$@"; do
    [[ $first -eq 0 ]] && line+="$SM"
    local seg; seg=$(printf "${SS}%.0s" $(seq 1 $((w+2))))
    line+="$seg"
    first=0
  done
  line+="$SR"
  printf '%b%s%b\n' "${DIM}${CYN}" "$line" "${R}"
}

# Imprime una celda: " contenido(padded) |"
cell() {
  local content="$1" width=$2 color="$3" sel_bg="$4"
  local padded; padded=$(trunc_to "$content" "$width")
  printf '%b%b %s %b%b%s%b' \
    "$sel_bg" "$color" "$padded" "${R}" \
    "${CYN}" "${V}" "${R}"
}

# Celda que ya tiene ANSI (status) — pad con visual_len
cell_ansi() {
  local content="$1" width=$2 sel_bg="$3"
  local padded; padded=$(pad_to "$content" "$width")
  printf '%b %b %b%b%s%b' \
    "$sel_bg" "$padded" "${R}" \
    "${CYN}" "${V}" "${R}"
}

# ─────────────────────────────────────────────────
#  DATOS
# ─────────────────────────────────────────────────
FILTER_RUNNING=0; FILTER_NAME=""; FILTER_IMAGE=""; SHOW_STATS=1
declare -A STATS_CPU=() STATS_MEM=()

get_containers() {
  local fmt="{{.ID}}|{{.Names}}|{{.Image}}|{{.RunningFor}}|{{.Status}}|{{.Ports}}"
  local args=()
  [[ $FILTER_RUNNING -eq 1 ]] && args+=(--filter "status=running")
  [[ -n "$FILTER_NAME"  ]] && args+=(--filter "name=${FILTER_NAME}")
  [[ -n "$FILTER_IMAGE" ]] && args+=(--filter "ancestor=${FILTER_IMAGE}")
  docker ps -a "${args[@]}" --format "$fmt" 2>/dev/null || true
}

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
#  ANCHOS DINÁMICOS
# ─────────────────────────────────────────────────
W_ID=0; W_NAME=0; W_IMG=0; W_AGE=0
W_STAT=0; W_CPU=0; W_MEM=0; W_PORT=0

calc_widths() {
  local data="$1"
  # Mínimos = longitud de los headers de texto
  W_ID=${#T_H_ID};     W_NAME=${#T_H_NAME}
  W_IMG=${#T_H_IMG};   W_AGE=${#T_H_AGE}
  W_STAT=${#T_H_STAT}; W_CPU=${#T_H_CPU}
  W_MEM=${#T_H_MEM};   W_PORT=${#T_H_PORT}

  # Máximos razonables
  local MAX_ID=12  MAX_NAME=20 MAX_IMG=28 MAX_AGE=14
  local MAX_STAT=13 MAX_CPU=8  MAX_MEM=10 MAX_PORT=30
  local MIN_ID=4   MIN_NAME=6  MIN_IMG=8  MIN_AGE=6
  local MIN_STAT=8  MIN_CPU=4  MIN_MEM=6  MIN_PORT=6

  # Medir datos
  while IFS='|' read -r id name image age status ports; do
    local pc; pc=$(clean_ports "$ports")
    local cpu="${STATS_CPU[$name]:-}"; local mem="${STATS_MEM[$name]:-}"
    local stat_txt
    # status visible: "* healthy" etc — 2 + len
    if   [[ "$status" == *"healthy"*     ]]; then stat_txt="* ${T_HEALTHY}"
    elif [[ "$status" == *"Up"*          ]]; then stat_txt="> ${T_RUNNING}"
    elif [[ "$status" == *"Exited (0)"*  ]]; then stat_txt="- ${T_STOPPED}"
    elif [[ "$status" == *"Exited"*      ]]; then stat_txt="! ${T_EXITED}"
    elif [[ "$status" == *"Paused"*      ]]; then stat_txt="~ ${T_PAUSED}"
    elif [[ "$status" == *"Restarting"*  ]]; then stat_txt="@ ${T_RESTARTING}"
    else                                          stat_txt="? ${T_UNKNOWN}"; fi

    local lens=("${#id}" "${#name}" "${#image}" "${#age}" \
                "${#stat_txt}" "${#cpu}" "${#mem}" "${#pc}")
    local vars=(W_ID W_NAME W_IMG W_AGE W_STAT W_CPU W_MEM W_PORT)
    for i in "${!vars[@]}"; do
      local v=${vars[$i]}
      (( ${lens[$i]} > ${!v} )) && printf -v "$v" '%d' "${lens[$i]}"
    done
  done <<< "$data"

  # Clamp
  _cl() { local v=$1 mn=$2 mx=$3; (( v<mn ))&&v=$mn; (( v>mx ))&&v=$mx; echo $v; }
  W_ID=$(  _cl $W_ID   $MIN_ID   $MAX_ID  )
  W_NAME=$(_cl $W_NAME $MIN_NAME $MAX_NAME)
  W_IMG=$( _cl $W_IMG  $MIN_IMG  $MAX_IMG )
  W_AGE=$( _cl $W_AGE  $MIN_AGE  $MAX_AGE )
  W_STAT=$(_cl $W_STAT $MIN_STAT $MAX_STAT)
  W_CPU=$( _cl $W_CPU  $MIN_CPU  $MAX_CPU )
  W_MEM=$( _cl $W_MEM  $MIN_MEM  $MAX_MEM )
  W_PORT=$(_cl $W_PORT $MIN_PORT $MAX_PORT)

  # Ajustar si se desborda
  local TERM_W; TERM_W=$(tput cols 2>/dev/null || echo 120)
  # 8 columnas → 9 bordes ║ + 16 espacios padding (2 por celda)
  local AVAIL=$(( TERM_W - 9 - 16 ))
  local TOTAL=$(( W_ID+W_NAME+W_IMG+W_AGE+W_STAT+W_CPU+W_MEM+W_PORT ))

  if (( TOTAL > AVAIL )); then
    local EXCESS=$(( TOTAL - AVAIL ))
    for col in W_PORT W_IMG W_NAME W_AGE W_ID W_CPU W_MEM W_STAT; do
      declare -n _r=$col
      local _mn
      case $col in
        W_ID)   _mn=$MIN_ID;;   W_NAME) _mn=$MIN_NAME;; W_IMG)  _mn=$MIN_IMG;;
        W_AGE)  _mn=$MIN_AGE;;  W_STAT) _mn=$MIN_STAT;; W_CPU)  _mn=$MIN_CPU;;
        W_MEM)  _mn=$MIN_MEM;;  W_PORT) _mn=$MIN_PORT;; *)       _mn=4;;
      esac
      local _cut=$(( _r - _mn ))
      if (( _cut >= EXCESS )); then _r=$(( _r - EXCESS )); EXCESS=0; break
      else _r=$_mn; EXCESS=$(( EXCESS - _cut )); fi
    done
  fi
}

# ─────────────────────────────────────────────────
#  RENDER TABLA
# ─────────────────────────────────────────────────
render_table() {
  local data="$1" selected="${2:--1}"
  local WW=($W_ID $W_NAME $W_IMG $W_AGE $W_STAT $W_CPU $W_MEM $W_PORT)
  # Headers: solo texto sin emojis (los emojis van en el banner)
  local HEADERS=("$T_H_ID" "$T_H_NAME" "$T_H_IMG" "$T_H_AGE" \
                 "$T_H_STAT" "$T_H_CPU" "$T_H_MEM" "$T_H_PORT")

  local TOTAL RUNNING STOPPED
  TOTAL=$(printf '%s\n' "$data" | wc -l | tr -d ' ')
  RUNNING=$(printf '%s\n' "$data" | grep -c "Up" 2>/dev/null || echo 0)
  STOPPED=$(( TOTAL - RUNNING ))

  # Banner
  printf '\n%b  %s  %s  %s total  %s %s running  %s %s stopped  %s  %b\n\n' \
    "${BG_HDR}${B}${WHT}" \
    "🐳" "$T_TITLE" \
    "$TOTAL" "🟢" "$RUNNING" "🔴" "$STOPPED" \
    "$(date '+%H:%M:%S')" "${R}"

  # Borde superior
  hline "$TL" "$MT" "$HH" "$TR" "${WW[@]}"

  # Fila de cabecera
  printf '%b%s%b' "${CYN}" "${V}" "${R}"
  for i in "${!HEADERS[@]}"; do
    local hdr; hdr=$(trunc_to "${HEADERS[$i]}" "${WW[$i]}")
    printf ' %b%b%s%b %b%s%b' \
      "${B}" "${CYN}" "$hdr" "${R}" \
      "${CYN}" "${V}" "${R}"
  done
  echo ""

  # Separador doble
  hline "$ML" "$MX" "$HH" "$MR" "${WW[@]}"

  # Filas de datos
  local idx=0 first=1
  while IFS='|' read -r id name image age status ports; do
    [[ $first -eq 0 ]] && thin_hline "${WW[@]}"

    local stat_d cpu_d mem_d port_d RC SEL
    stat_d=$(status_fmt "$status")
    cpu_d="${STATS_CPU[$name]:-0.00%}"
    mem_d="${STATS_MEM[$name]:-—}"
    port_d=$(clean_ports "$ports")
    RC=$(row_color "$status")
    (( idx == selected )) && SEL="${BG_SEL}" || SEL=""

    printf '%b%s%b' "${CYN}" "${V}" "${R}"
    cell        "$id"     $W_ID   "$RC" "$SEL"
    cell        "$name"   $W_NAME "$RC" "$SEL"
    cell        "$image"  $W_IMG  "$RC" "$SEL"
    cell        "$age"    $W_AGE  "$RC" "$SEL"
    cell_ansi   "$stat_d" $W_STAT        "$SEL"
    cell        "$cpu_d"  $W_CPU  "${GRN}" "$SEL"
    cell        "$mem_d"  $W_MEM  "${YLW}" "$SEL"
    cell        "$port_d" $W_PORT "$RC" "$SEL"
    echo ""

    (( idx++ )) || true; first=0
  done <<< "$data"

  # Borde inferior
  hline "$BL" "$MB" "$HH" "$BR" "${WW[@]}"
  echo ""
}

# ─────────────────────────────────────────────────
#  MODOS
# ─────────────────────────────────────────────────
mode_once() {
  local data; data=$(get_containers)
  [[ -z "$data" ]] && { printf '\n  %b%s%b\n\n' "${YLW}" "$T_EMPTY" "${R}"; exit 0; }
  [[ $SHOW_STATS -eq 1 ]] && fetch_stats
  calc_widths "$data"
  render_table "$data" -1
}

mode_watch() {
  local interval="${1:-2}"
  trap 'tput cnorm; echo ""; exit 0' INT TERM
  tput civis
  while true; do
    local data; data=$(get_containers)
    [[ $SHOW_STATS -eq 1 ]] && fetch_stats
    [[ -n "$data" ]] && calc_widths "$data"
    clear
    if [[ -z "$data" ]]; then
      printf '\n  %b%s%b\n\n' "${YLW}" "$T_EMPTY" "${R}"
    else
      render_table "$data" -1
    fi
    printf '  %b%s · refresh %ss%b\n' "${DIM}" "$T_WATCH_HINT" "$interval" "${R}"
    sleep "$interval"
  done
  tput cnorm
}

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
  trap '_tui_exit; exit 0' INT TERM
  _tui_exit() { tput cnorm; tput rmcup 2>/dev/null || true; }
  tput smcup 2>/dev/null || true; tput civis

  local selected=0 data="" names=()

  _refresh() {
    data=$(get_containers); names=()
    [[ $SHOW_STATS -eq 1 ]] && fetch_stats
    if [[ -n "$data" ]]; then
      calc_widths "$data"
      while IFS='|' read -r _ name _rest; do names+=("$name"); done <<< "$data"
    fi
    local c=${#names[@]}
    (( c==0 )) && selected=0
    (( selected>=c && c>0 )) && selected=$(( c-1 ))
    (( selected<0 )) && selected=0
  }

  _draw() {
    tput cup 0 0; clear
    if [[ -z "$data" || ${#names[@]} -eq 0 ]]; then
      printf '\n  %b%s%b\n\n' "${YLW}" "$T_EMPTY" "${R}"
    else
      render_table "$data" "$selected"
      printf '%b%s%b\n' "${DIM}" "$T_KEYS" "${R}"
      printf '  %b%s:%b %b%s%b\n' \
        "${DIM}" "$T_SELECTED" "${R}" "${B}${WHT}" "${names[$selected]:-—}" "${R}"
    fi
  }

  _confirm() {
    local prompt="$1"
    tput cup $(( $(tput lines)-2 )) 0
    printf '%b' "${R}"
    printf "$prompt"
    tput cnorm; local ans; read -r ans; tput civis
    [[ "${ans,,}" == "${T_YES_CHAR}" ]]
  }

  _refresh; _draw

  while true; do
    local key; key=$(read_key)
    local count=${#names[@]}
    case "$key" in
      $'\x1b[A'|k) (( count>0 && selected>0 )) && (( selected-- )) ;;
      $'\x1b[B'|j) (( count>0 && selected<count-1 )) && (( selected++ )) ;;
      l|L)
        local cn="${names[$selected]:-}"; [[ -n "$cn" ]] && {
          tput cnorm; tput rmcup 2>/dev/null || true
          docker logs --tail 80 -f "$cn"
          tput smcup 2>/dev/null || true; tput civis; _refresh; } ;;
      s|S)
        local cn="${names[$selected]:-}"; [[ -n "$cn" ]] && {
          _confirm "$(printf "$T_CONFIRM_STOP" "$cn")" &&
            docker stop "$cn" >/dev/null 2>&1 || true; _refresh; } ;;
      r|R)
        local cn="${names[$selected]:-}"; [[ -n "$cn" ]] && {
          _confirm "$(printf "$T_CONFIRM_RESTART" "$cn")" &&
            docker restart "$cn" >/dev/null 2>&1 || true; _refresh; } ;;
      d|D)
        local cn="${names[$selected]:-}"; [[ -n "$cn" ]] && {
          _confirm "$(printf "$T_CONFIRM_DELETE" "$cn")" &&
            docker rm -f "$cn" >/dev/null 2>&1 || true; _refresh
          (( selected>0 && selected>=${#names[@]} )) && (( selected-- )) || true; } ;;
      c|C)
        _confirm "$T_CONFIRM_CLEAN" && {
          docker container prune -f >/dev/null 2>&1 || true
          docker image prune -f >/dev/null 2>&1 || true; }; _refresh ;;
      w|W) _refresh ;;
      f|F) (( FILTER_RUNNING==0 )) && FILTER_RUNNING=1 || FILTER_RUNNING=0; _refresh ;;
      q|Q) break ;;
    esac
    _draw
  done
  _tui_exit
}

# ─────────────────────────────────────────────────
#  SUBCOMANDOS & AYUDA
# ─────────────────────────────────────────────────
cmd_logs()    { docker logs --tail 80 -f "$1"; }
cmd_stop()    { docker stop    "$1" && printf '%b Done%b\n' "${GRN}" "${R}"; }
cmd_restart() { docker restart "$1" && printf '%b Done%b\n' "${GRN}" "${R}"; }
cmd_clean()   {
  printf '%b%s%b\n' "${YLW}" "$T_CLEANING" "${R}"
  docker container prune -f; docker image prune -f
  printf '%b%s%b\n' "${GRN}" "$T_DONE" "${R}"
}

usage() {
  printf '%b\ndps v%s%b — Docker Pretty Status\n\n' "${B}${CYN}" "$VERSION" "${R}"
  printf 'Usage:\n'
  printf '  dps                    Show table\n'
  printf '  dps watch [secs]       Auto-refresh (default 2s)\n'
  printf '  dps -i                 Interactive TUI\n'
  printf '  dps logs <name>        Stream logs\n'
  printf '  dps stop <name>        Stop container\n'
  printf '  dps restart <name>     Restart container\n'
  printf '  dps clean              Prune stopped + orphan images\n'
  printf '  dps config             Change language\n\n'
  printf 'Filters:\n'
  printf '  --running  --name <p>  --image <i>  --no-stats\n\n'
}

# ─────────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────────
main() {
  init_config
  load_strings

  local MODE="once" WATCH_INT=2 SUBCMD="" SUBCMD_ARG=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      watch)        MODE="watch"
                    [[ $# -gt 1 && "$2" =~ ^[0-9]+$ ]] && { WATCH_INT=$2; shift; } ;;
      interactive|-i) MODE="interactive" ;;
      logs)         SUBCMD="logs";    [[ $# -gt 1 ]] && { SUBCMD_ARG=$2; shift; } ;;
      stop)         SUBCMD="stop";    [[ $# -gt 1 ]] && { SUBCMD_ARG=$2; shift; } ;;
      restart)      SUBCMD="restart"; [[ $# -gt 1 ]] && { SUBCMD_ARG=$2; shift; } ;;
      clean)        SUBCMD="clean" ;;
      config)       rm -f "$CONFIG_FILE"; init_config; load_strings; return ;;
      --running)    FILTER_RUNNING=1 ;;
      --name)       [[ $# -gt 1 ]] && { FILTER_NAME=$2;  shift; } ;;
      --image)      [[ $# -gt 1 ]] && { FILTER_IMAGE=$2; shift; } ;;
      --no-stats)   SHOW_STATS=0 ;;
      --version|-v) echo "dps v${VERSION}"; exit 0 ;;
      --help|-h)    usage; exit 0 ;;
      *) printf '%bUnknown: %s%b\n' "${RED}" "$1" "${R}" >&2; usage; exit 1 ;;
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