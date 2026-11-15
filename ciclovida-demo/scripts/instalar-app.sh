#!/usr/bin/env bash
# =============================================================================
# instalar-app.sh - Compila la app (debug), la instala en el emulador de la
# demo y la abre.
# Uso:  ./scripts/instalar-app.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/comun.sh"
usar_emulador_demo

cd "$RAIZ_PROYECTO"

info "Compilando (debug)..."
./gradlew assembleDebug

APK="$RAIZ_PROYECTO/app/build/outputs/apk/debug/app-debug.apk"
if [ ! -f "$APK" ]; then
    error "No se generó el APK en $APK"
    exit 1
fi

info "Instalando en $ANDROID_SERIAL ..."
# En Windows adb necesita la ruta en formato Windows.
if es_windows; then APK_ADB="$(cygpath -w "$APK")"; else APK_ADB="$APK"; fi
"$ADB" install -r "$APK_ADB"

info "Abriendo la app..."
"$ADB" shell am start -n "$ACTIVITY"

ok "App instalada y abierta. Para ver los eventos en la terminal:  ./scripts/logcat.sh"
