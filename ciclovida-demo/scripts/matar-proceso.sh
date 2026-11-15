#!/usr/bin/env bash
# =============================================================================
# matar-proceso.sh - BONUS: simula que Android mata la app por falta de memoria.
#
#   1. Envía la app a segundo plano (botón Inicio).
#   2. Mata el proceso (como haría el sistema).
#   3. Te dice qué hacer y qué deberías ver.
#
# Antes de ejecutarlo: enciende "Mostrar soluciones" y pon, por ejemplo,
# los tres contadores en 7.
# Uso:  ./scripts/matar-proceso.sh
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/comun.sh"
usar_emulador_demo

info "1) Enviando la app a segundo plano (Inicio)..."
"$ADB" shell input keyevent KEYCODE_HOME
# Se espera a que lleguen onPause, onStop y onSaveInstanceState.
sleep 2

info "2) Matando el proceso de $PAQUETE ..."
"$ADB" shell am kill "$PAQUETE"
sleep 1

if "$ADB" shell pidof "$PAQUETE" >/dev/null 2>&1; then
    aviso "El proceso sigue vivo. ¿La app estaba en primer plano? Vuelve a intentarlo."
    exit 1
fi
ok "Proceso eliminado (la app ya no está en memoria)."

cat <<'TEXTO'

==================== QUÉ HACER AHORA ====================
1. En el emulador, abre "Recientes" (botón cuadrado o desliza hacia arriba)
   y toca la tarjeta de "Ciclo de vida".

2. Qué deberías ver:
   - Contador A (remember)        -> 0   (se pierde)
   - Contador B (rememberSaveable)-> 7   (SOBREVIVE: estaba en el Bundle guardado)
   - Contador C (ViewModel)       -> 0   (se pierde: el ViewModel vivía en memoria)
   - El interruptor "Mostrar soluciones" sigue encendido (rememberSaveable).
   - El registro empieza de nuevo: solo onCreate, onStart, onResume.
     El objeto LogCicloVida también vivía en el proceso que se mató.
   - Cambia el identificador de instancia de la Activity.

Conclusión: para sobrevivir a la muerte del proceso hay que guardar el estado
(rememberSaveable / SavedStateHandle) y no solo tenerlo en memoria.
==========================================================
TEXTO
