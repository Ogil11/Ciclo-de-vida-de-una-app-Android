package com.demo.ciclovida

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme

/**
 * La única Activity de la app.
 *
 * Todos los callbacks siguen el MISMO patrón:
 *   1. llamar a super (obligatorio en Android),
 *   2. llamar a registrar("onXxx") para verlo en pantalla y en Logcat.
 */
class MainActivity : ComponentActivity() {

    // CICLO DE VIDA: onCreate -> la Activity se crea. Aquí se construye la interfaz.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        registrar("onCreate")

        // Identificador corto de ESTA instancia de la Activity.
        // Al rotar se crea una Activity nueva, así que este valor cambia.
        val idInstancia = "%04X".format(hashCode() and 0xFFFF)

        setContent {
            MaterialTheme {
                PantallaCicloVida(
                    idInstancia = idInstancia,
                    alCerrarApp = { finish() }
                )
            }
        }
    }

    // CICLO DE VIDA: onStart -> la Activity se vuelve visible.
    override fun onStart() {
        super.onStart()
        registrar("onStart")
    }

    // CICLO DE VIDA: onResume -> la Activity está en primer plano y recibe toques.
    override fun onResume() {
        super.onResume()
        registrar("onResume")
    }

    // CICLO DE VIDA: onPause -> la Activity deja de estar en primer plano.
    override fun onPause() {
        super.onPause()
        registrar("onPause")
    }

    // CICLO DE VIDA: onStop -> la Activity ya no es visible.
    override fun onStop() {
        super.onStop()
        registrar("onStop")
    }

    // CICLO DE VIDA: onRestart -> la Activity vuelve después de un onStop (sin onCreate).
    override fun onRestart() {
        super.onRestart()
        registrar("onRestart")
    }

    // CICLO DE VIDA: onSaveInstanceState -> el sistema guarda el estado pequeño de la
    // pantalla (aquí se guarda lo que usa rememberSaveable).
    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        registrar("onSaveInstanceState")
    }

    // CICLO DE VIDA: onDestroy -> la Activity se destruye.
    // isChangingConfigurations = true  -> se destruye por un cambio de configuración (rotar).
    // isFinishing             = true  -> se destruye porque terminó (Atrás o finish()).
    override fun onDestroy() {
        super.onDestroy()
        val rotacion = if (isChangingConfigurations) "sí" else "no"
        val terminada = if (isFinishing) "sí" else "no"
        registrar("onDestroy (rotación: $rotacion, finish: $terminada)")
    }

    /** Añade el evento al registro de la pantalla y a Logcat (tag "CicloVida"). */
    private fun registrar(evento: String) {
        LogCicloVida.registrar(evento)
    }
}
