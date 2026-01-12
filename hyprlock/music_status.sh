#!/bin/bash
# Intenta obtener la canción. Si falla, escribe "Sin música"
/usr/bin/playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo "Sin música"
