package com.demo.ciclovida

import android.util.Log
import androidx.compose.runtime.mutableStateListOf
import java.time.LocalTime
import java.time.format.DateTimeFormatter

/** Tipo de evento. Solo sirve para elegir el color de la fila. */
enum class TipoEvento {
    SUBIDA,   // onCreate, onStart, onResume, onRestart  -> verde
    BAJADA,   // onPause, onStop, onDestroy               -> ámbar
    GUARDADO  // onSaveInstanceState                      -> azul
}

/** Una fila del registro: hora, nombre del evento y su tipo. */
data class EventoCicloVida(
    val hora: String,
    val nombre: String,
    val tipo: TipoEvento
)

/**
 * Registro de eventos del ciclo de vida.
 *
 * Es un `object` (un único ejemplar para todo el PROCESO). Por eso NO se borra
 * al rotar: la Activity se destruye y se crea otra, pero el proceso sigue vivo.
 * Si el sistema mata el proceso, este registro sí se pierde.
 */
object LogCicloVida {

    private const val TAG = "CicloVida"
    private const val MAXIMO_FILAS = 40
    private val formatoHora = DateTimeFormatter.ofPattern("HH:mm:ss")

    // Lista observable de Compose: cuando cambia, la pantalla se vuelve a dibujar sola.
    // El evento más reciente va en la posición 0 (arriba).
    val eventos = mutableStateListOf<EventoCicloVida>()

    /** Añade un evento arriba de la lista y lo imprime en Logcat. */
    fun registrar(nombre: String) {
        val hora = LocalTime.now().format(formatoHora)
        eventos.add(0, EventoCicloVida(hora, nombre, tipoDe(nombre)))

        // Se guardan como máximo 40 filas: se borran las más antiguas (abajo).
        while (eventos.size > MAXIMO_FILAS) {
            eventos.removeAt(eventos.lastIndex)
        }

        Log.d(TAG, nombre)
    }

    /** Vacía la lista (botón "Limpiar registro"). */
    fun limpiar() {
        eventos.clear()
        Log.d(TAG, "--- registro limpiado ---")
    }

    /** Decide el tipo (y por tanto el color) según el nombre del callback. */
    private fun tipoDe(nombre: String): TipoEvento = when {
        nombre.startsWith("onSaveInstanceState") -> TipoEvento.GUARDADO
        nombre.startsWith("onPause") -> TipoEvento.BAJADA
        nombre.startsWith("onStop") -> TipoEvento.BAJADA
        nombre.startsWith("onDestroy") -> TipoEvento.BAJADA
        else -> TipoEvento.SUBIDA
    }
}
