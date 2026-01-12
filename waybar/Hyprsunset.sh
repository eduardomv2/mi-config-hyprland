#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURACIÓN ---
STATE_FILE="$HOME/.cache/.hyprsunset_state"
TARGET_TEMP="${HYPRSUNSET_TEMP:-4500}"
ICON_MODE="${HYPRSUNSET_ICON_MODE:-sunset}"

# --- SEÑAL DE WAYBAR (IMPORTANTE) ---
# Asegúrate de poner "signal": 8 en tu config de waybar para este módulo.
# Esto hace que el icono cambie INSTANTÁNEAMENTE.
WAYBAR_SIGNAL=8

ensure_state() {
  [[ -f "$STATE_FILE" ]] || echo "off" > "$STATE_FILE"
}

icon_off() {
  printf "☀"
}

icon_on() {
  case "$ICON_MODE" in
    sunset) printf "❍" ;;
    blue)   printf "☀" ;;
    *)      printf "☀" ;;
  esac
}

cmd_toggle() {
  ensure_state
  state="$(cat "$STATE_FILE" || echo off)"

  # cerrar cualquier instancia
  if pgrep -x hyprsunset >/dev/null 2>&1; then
    pkill -x hyprsunset || true
    sleep 0.1
  fi

  if [[ "$state" == "on" ]]; then
    # --- APAGANDO ---
    
   
    echo "off" > "$STATE_FILE"
    
    
    pkill -RTMIN+${WAYBAR_SIGNAL} waybar || true
    
    
    if command -v hyprsunset >/dev/null 2>&1; then
      nohup hyprsunset -i >/dev/null 2>&1 &
      
      sleep 0.3 && pkill -x hyprsunset || true
    fi
    
    notify-send -u low "Modo Lectura" "Desactivado" || true
    
  else
    
    
    if command -v hyprsunset >/dev/null 2>&1; then
      nohup hyprsunset -t "$TARGET_TEMP" >/dev/null 2>&1 &
    fi
    
    echo "on" > "$STATE_FILE"
    pkill -RTMIN+${WAYBAR_SIGNAL} waybar || true
    notify-send -u low "Modo Lectura" "Activado (${TARGET_TEMP}K)" || true
  fi
}

cmd_status() {
  ensure_state
  
  # --- CORRECCIÓN ---
  # Leemos SOLO el archivo. Ignoramos pgrep porque pgrep es lento 
  # y se confunde cuando estamos apagando el proceso.
  onoff="$(cat "$STATE_FILE" || echo off)"

  if [[ "$onoff" == "on" ]]; then
    txt="<span size='18pt'>$(icon_on)</span>"
    cls="on"
    tip="Night light on @ ${TARGET_TEMP}K"
  else
    txt="<span size='16pt'>$(icon_off)</span>"
    cls="off"
    tip="Night light off"
  fi
  
  
  printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$txt" "$cls" "$tip"
}

cmd_init() {
  ensure_state
  state="$(cat "$STATE_FILE" || echo off)"

  
  if [[ "$state" == "on" ]]; then
    if command -v hyprsunset >/dev/null 2>&1; then
      
       if ! pgrep -x hyprsunset >/dev/null 2>&1; then
         nohup hyprsunset -t "$TARGET_TEMP" >/dev/null 2>&1 &
       fi
    fi
  fi
}

case "${1:-}" in
  toggle) cmd_toggle ;;
  status) cmd_status ;;
  init) cmd_init ;;
  *) echo "usage: $0 [toggle|status|init]" >&2; exit 2 ;;
esac
