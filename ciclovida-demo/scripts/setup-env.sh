#!/usr/bin/env bash
# =============================================================================
# setup-env.sh - Prepara la máquina para la demo. Se puede ejecutar varias veces:
# solo instala lo que falte (idempotente).
#
#   1. JDK 17
#   2. git
#   3. Android SDK: cmdline-tools, platform-tools, platforms;android-35,
#      build-tools, emulator y la imagen de Android 14 (API 34, google_apis)
#   4. El AVD "ciclovida_api34" (Pixel, 2 GB de RAM)
#   5. local.properties con la ruta del SDK
#
# NO toca otros AVD que ya existan (por ejemplo mibanco_api34).
# Uso:  ./scripts/setup-env.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/comun.sh"

BUILD_TOOLS="36.0.0"   # AGP 9.5 pide build-tools 36.0.0

# --- Arquitectura de la CPU -> imagen del emulador ---
case "$(uname -m)" in
    arm64|aarch64) ABI="arm64-v8a" ;;
    *)             ABI="x86_64" ;;
esac
IMAGEN="system-images;android-34;google_apis;$ABI"

echo "=== Preparando el entorno de la demo 'Ciclo de vida' ==="
info "Android SDK: $SDK"
info "Imagen del emulador: $IMAGEN"
echo

# -----------------------------------------------------------------------------
# 1. JDK 17
# -----------------------------------------------------------------------------
version_java() {
    java -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/'
}

if command -v java >/dev/null 2>&1 && [ "$(version_java)" = "17" ]; then
    ok "JDK 17 instalado: $(java -version 2>&1 | head -1)"
else
    aviso "No se encontró JDK 17 en el PATH. Intentando instalarlo..."
    if es_windows && command -v winget >/dev/null 2>&1; then
        # Puede pedir permisos de administrador (ventana de Windows).
        winget install --id EclipseAdoptium.Temurin.17.JDK -e --accept-source-agreements --accept-package-agreements
    elif command -v brew >/dev/null 2>&1; then
        brew install --cask temurin@17
    elif command -v apt-get >/dev/null 2>&1; then
        echo "Requiere administrador. Ejecuta:  sudo apt-get install -y openjdk-17-jdk"
        exit 1
    else
        error "Instala JDK 17 a mano: https://adoptium.net/temurin/releases/?version=17"
        exit 1
    fi
    aviso "Cierra y abre de nuevo la terminal para que java quede en el PATH, y vuelve a ejecutar este script."
    exit 1
fi

# -----------------------------------------------------------------------------
# 2. git
# -----------------------------------------------------------------------------
if command -v git >/dev/null 2>&1; then
    ok "git instalado: $(git --version)"
else
    aviso "No se encontró git. Intentando instalarlo..."
    if es_windows && command -v winget >/dev/null 2>&1; then
        winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
    elif command -v brew >/dev/null 2>&1; then
        brew install git
    else
        echo "Requiere administrador. Ejecuta:  sudo apt-get install -y git"
        exit 1
    fi
fi

# -----------------------------------------------------------------------------
# 3a. cmdline-tools (contiene sdkmanager y avdmanager)
# -----------------------------------------------------------------------------
if [ -f "$SDKMANAGER" ]; then
    ok "cmdline-tools instaladas"
else
    aviso "Faltan las cmdline-tools. Descargándolas en $SDK/cmdline-tools/latest ..."
    if es_windows; then SO="win"; elif [ "$(uname -s)" = "Darwin" ]; then SO="mac"; else SO="linux"; fi
    # Se busca el nombre del zip más reciente en el repositorio oficial de Google.
    ZIP="$(curl -s https://dl.google.com/android/repository/repository2-3.xml \
        | grep -o "commandlinetools-$SO-[0-9]*_latest.zip" | sort -t- -k3 -n | tail -1)"
    if [ -z "$ZIP" ]; then
        error "No se pudo consultar dl.google.com. ¿Hay internet?"
        exit 1
    fi
    TMP="$(mktemp -d)"
    curl -L -o "$TMP/$ZIP" "https://dl.google.com/android/repository/$ZIP"
    unzip -q "$TMP/$ZIP" -d "$TMP"
    mkdir -p "$SDK/cmdline-tools"
    rm -rf "$SDK/cmdline-tools/latest"
    mv "$TMP/cmdline-tools" "$SDK/cmdline-tools/latest"
    rm -rf "$TMP"
    ok "cmdline-tools instaladas"
fi

# -----------------------------------------------------------------------------
# 3b. Paquetes del SDK (solo se instalan los que falten)
# -----------------------------------------------------------------------------
# Cada paquete se comprueba por la carpeta que crea en el SDK.
instalar_si_falta() {
    local paquete="$1"
    local carpeta="$SDK/$(echo "$paquete" | tr ';' '/')"
    if [ -d "$carpeta" ]; then
        ok "$paquete"
    else
        info "Instalando $paquete ..."
        yes | "$SDKMANAGER" --sdk_root="$SDK" --licenses >/dev/null 2>&1 || true
        "$SDKMANAGER" --sdk_root="$SDK" "$paquete"
        ok "$paquete instalado"
    fi
}

instalar_si_falta "platform-tools"
instalar_si_falta "platforms;android-35"
instalar_si_falta "build-tools;$BUILD_TOOLS"
instalar_si_falta "emulator"
instalar_si_falta "$IMAGEN"

# -----------------------------------------------------------------------------
# 4. AVD de la demo
# -----------------------------------------------------------------------------
CARPETA_AVDS="${ANDROID_AVD_HOME:-$HOME/.android/avd}"
CONFIG_AVD="$CARPETA_AVDS/$NOMBRE_AVD.avd/config.ini"

if "$EMULADOR" -list-avds 2>/dev/null | tr -d '\r' | grep -qx "$NOMBRE_AVD"; then
    ok "El AVD '$NOMBRE_AVD' ya existe"
else
    info "Creando el AVD '$NOMBRE_AVD' (Pixel, Android 14) ..."
    echo "no" | "$AVDMANAGER" create avd \
        --name "$NOMBRE_AVD" \
        --package "$IMAGEN" \
        --device "pixel"
    ok "AVD creado"
fi

# 2 GB de RAM y teclado físico (para escribir desde el PC). Solo se toca NUESTRO AVD.
if [ -f "$CONFIG_AVD" ]; then
    poner_opcion() {
        local clave="$1" valor="$2"
        # Se busca "clave=" exacta (para no tocar, p. ej., hw.keyboard.lid).
        if grep -q "^$clave=" "$CONFIG_AVD"; then
            sed -i "s|^$clave=.*|$clave=$valor|" "$CONFIG_AVD"
        else
            echo "$clave=$valor" >> "$CONFIG_AVD"
        fi
    }
    poner_opcion "hw.ramSize" "2048"
    poner_opcion "hw.keyboard" "yes"
    ok "AVD configurado con 2 GB de RAM"
else
    aviso "No se encontró $CONFIG_AVD (no se pudo fijar la RAM)."
fi

# -----------------------------------------------------------------------------
# 5. local.properties (para Android Studio y Gradle)
# -----------------------------------------------------------------------------
LOCAL_PROPS="$RAIZ_PROYECTO/local.properties"
if [ -f "$LOCAL_PROPS" ]; then
    ok "local.properties ya existe"
else
    if es_windows; then
        # Formato Windows: C\:\\Android\\Sdk
        RUTA_WIN="$(cygpath -w "$SDK" | sed 's/\\/\\\\/g; s/:/\\:/')"
        echo "sdk.dir=$RUTA_WIN" > "$LOCAL_PROPS"
    else
        echo "sdk.dir=$SDK" > "$LOCAL_PROPS"
    fi
    ok "local.properties creado"
fi

echo
ok "Entorno listo. Siguiente paso:  ./scripts/start-emulator.sh"
