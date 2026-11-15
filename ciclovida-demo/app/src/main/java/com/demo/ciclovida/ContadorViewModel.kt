package com.demo.ciclovida

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel

/**
 * ViewModel del contador C.
 *
 * SOLUCIÓN: el ViewModel vive FUERA de la Activity. Cuando se rota, la Activity
 * vieja se destruye pero el sistema le entrega el MISMO ViewModel a la nueva,
 * así que el valor se conserva.
 *
 * A propósito NO usa SavedStateHandle: si el sistema mata el proceso, el
 * ViewModel desaparece con él y el contador vuelve a 0.
 */
class ContadorViewModel : ViewModel() {

    var n by mutableIntStateOf(0)
        private set

    fun sumar() {
        n++
    }

    fun reiniciar() {
        n = 0
    }
}
