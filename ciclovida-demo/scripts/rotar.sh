#!/usr/bin/env bash
# =============================================================================
# rotar.sh - Alterna el emulador entre vertical y horizontal desde la terminal.
#
# Cómo funciona:
#   1. Desactiva la rotación automática:  settings put system accelerometer_rotation 0
#   2. Fija la orientación a mano:        settings put system user_rotation 0 (vertical)
#                                                                         o 1 (horizontal)
#
# Para VOLVER a la rotación automática (la del sensor / botones del emulador):
#   ./scripts/rotar.sh auto
#   (equivale a: adb shell settings put system accelerometer_rotation 1)
#
# Uso:  ./scripts/rotar.sh          -> alterna vertical <-> horizontal
#       ./scripts/rotar.sh auto     -> vuelve a rotación automática
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/comun.sh"
usar_emulador_demo

if [ "${1:-}" = "auto" ]; then
    "$ADB" shell settings put system accelerometer_rotation 1
    ok "Rotación automática activada de nuevo"
    exit 0
fi

ACTUAL="$("$ADB" shell settings get system user_rotation | tr -d '\r')"

"$ADB" shell settings put system accelerometer_rotation 0
if [ "$ACTUAL" = "1" ]; then
    "$ADB" shell settings put system user_rotation 0
    ok "Ahora en VERTICAL"
else
    "$ADB" shell settings put system user_rotation 1
    ok "Ahora en HORIZONTAL"
fi
