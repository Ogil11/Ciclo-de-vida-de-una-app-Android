#!/usr/bin/env bash
# =============================================================================
# comun.sh - Variables y funciones compartidas por todos los scripts.
# No se ejecuta solo: los demás scripts lo cargan con "source".
# En Windows, ejecuta los scripts desde Git Bash.
# =============================================================================

NOMBRE_AVD="ciclovida_api34"
PAQUETE="com.demo.ciclovida"
ACTIVITY="com.demo.ciclovida/.MainActivity"

# Carpeta raíz del proyecto (la que contiene gradlew).
RAIZ_PROYECTO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ¿Estamos en Windows (Git Bash)?
es_windows() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*) return 0 ;;
        *) return 1 ;;
    esac
}

# --- Localizar el Android SDK: ANDROID_HOME, ANDROID_SDK_ROOT o rutas típicas ---
buscar_sdk() {
    local candidatos=(
        "${ANDROID_HOME:-}"
        "${ANDROID_SDK_ROOT:-}"
        "/c/Android/Sdk"
        "$HOME/AppData/Local/Android/Sdk"
        "$HOME/Library/Android/sdk"
        "$HOME/Android/Sdk"
    )
    local c
    for c in "${candidatos[@]}"; do
        if [ -n "$c" ] && [ -d "$c" ]; then
            echo "$c"
            return 0
        fi
    done
    # Si no existe ninguno, se propone la ruta por defecto de cada sistema.
    if es_windows; then echo "/c/Android/Sdk"; else echo "$HOME/Android/Sdk"; fi
}

SDK="$(buscar_sdk)"
export ANDROID_HOME="$SDK"

# Ejecutables (en Windows llevan .exe o .bat).
if es_windows; then
    ADB="$SDK/platform-tools/adb.exe"
    EMULADOR="$SDK/emulator/emulator.exe"
    SDKMANAGER="$SDK/cmdline-tools/latest/bin/sdkmanager.bat"
    AVDMANAGER="$SDK/cmdline-tools/latest/bin/avdmanager.bat"
else
    ADB="$SDK/platform-tools/adb"
    EMULADOR="$SDK/emulator/emulator"
    SDKMANAGER="$SDK/cmdline-tools/latest/bin/sdkmanager"
    AVDMANAGER="$SDK/cmdline-tools/latest/bin/avdmanager"
fi

# --- Mensajes con formato ---
info()  { echo "[i] $*"; }
ok()    { echo "[OK] $*"; }
aviso() { echo "[!] $*"; }
error() { echo "[ERROR] $*" >&2; }

# --- Comprobar que adb existe ---
requerir_adb() {
    if [ ! -x "$ADB" ] && [ ! -f "$ADB" ]; then
        error "No se encontró adb en $ADB"
        error "Ejecuta primero: ./scripts/setup-env.sh"
        exit 1
    fi
}

# --- Encontrar el emulador que corre el AVD de la demo ---
# Si hay varios dispositivos conectados, devuelve el serial (emulator-5554...)
# del que ejecuta $NOMBRE_AVD. Si no lo encuentra, devuelve vacío.
serial_demo() {
    local s
    for s in $("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}' | tr -d '\r'); do
        case "$s" in
            emulator-*)
                if "$ADB" -s "$s" emu avd name 2>/dev/null | tr -d '\r' | head -1 | grep -qx "$NOMBRE_AVD"; then
                    echo "$s"
                    return 0
                fi
                ;;
        esac
    done
    return 1
}

# --- Dejar fijado ANDROID_SERIAL para que todos los "adb" vayan al emulador de la demo ---
usar_emulador_demo() {
    requerir_adb
    local s
    s="$(serial_demo)"
    if [ -z "$s" ]; then
        error "El emulador '$NOMBRE_AVD' no está encendido."
        error "Ejecuta primero: ./scripts/start-emulator.sh"
        exit 1
    fi
    export ANDROID_SERIAL="$s"
}
