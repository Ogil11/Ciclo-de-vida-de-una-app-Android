#!/usr/bin/env bash
# =============================================================================
# start-emulator.sh - Arranca el AVD "ciclovida_api34" y espera a que termine
# de arrancar. Luego:
#   - quita cualquier proxy configurado en el emulador,
#   - activa la rotación automática.
# Si ya estaba encendido, solo aplica los ajustes.
# Uso:  ./scripts/start-emulator.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/comun.sh"
requerir_adb

if ! "$EMULADOR" -list-avds 2>/dev/null | tr -d '\r' | grep -qx "$NOMBRE_AVD"; then
    error "No existe el AVD '$NOMBRE_AVD'. Ejecuta primero: ./scripts/setup-env.sh"
    exit 1
fi

"$ADB" start-server >/dev/null 2>&1 || true

SERIAL="$(serial_demo || true)"
if [ -n "$SERIAL" ]; then
    ok "El emulador ya está encendido ($SERIAL)"
else
    info "Arrancando el emulador '$NOMBRE_AVD' (la primera vez tarda 1-3 minutos)..."
    REGISTRO="${TMPDIR:-/tmp}/emulador-$NOMBRE_AVD.log"
    # Se lanza en segundo plano y desligado de esta terminal.
    nohup "$EMULADOR" -avd "$NOMBRE_AVD" -netdelay none -netspeed full \
        > "$REGISTRO" 2>&1 &
    disown || true

    # Esperar a que aparezca en "adb devices".
    for i in $(seq 1 90); do
        SERIAL="$(serial_demo || true)"
        [ -n "$SERIAL" ] && break
        sleep 2
    done
    if [ -z "$SERIAL" ]; then
        error "El emulador no apareció en adb tras 3 minutos. Mira el registro: $REGISTRO"
        exit 1
    fi
    info "Emulador detectado ($SERIAL). Esperando a que Android termine de arrancar..."
fi
export ANDROID_SERIAL="$SERIAL"

# Esperar a sys.boot_completed = 1 (máximo 5 minutos).
for i in $(seq 1 150); do
    LISTO="$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
    [ "$LISTO" = "1" ] && break
    sleep 2
done
if [ "$LISTO" != "1" ]; then
    error "Android no terminó de arrancar en 5 minutos."
    exit 1
fi
ok "Android arrancado"

# Sin proxy (un proxy heredado puede dejar el emulador sin red).
"$ADB" shell settings put global http_proxy :0
# Rotación automática activada.
"$ADB" shell settings put system accelerometer_rotation 1
# Desbloquear la pantalla, por si acaso.
"$ADB" shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
"$ADB" shell wm dismiss-keyguard >/dev/null 2>&1 || true

ok "Proxy desactivado y rotación automática activada"
echo
ok "Siguiente paso:  ./scripts/instalar-app.sh"
