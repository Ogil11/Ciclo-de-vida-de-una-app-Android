#!/usr/bin/env bash
# =============================================================================
# logcat.sh - Muestra en la terminal solo los mensajes con el tag "CicloVida".
# Cada callback de la Activity escribe ahí (Log.d). Ctrl+C para salir.
# Uso:  ./scripts/logcat.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/comun.sh"
usar_emulador_demo

info "Mostrando el tag CicloVida (Ctrl+C para salir)..."
"$ADB" logcat -v time -s CicloVida
