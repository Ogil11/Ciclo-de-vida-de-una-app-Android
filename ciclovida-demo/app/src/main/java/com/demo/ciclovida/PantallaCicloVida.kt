package com.demo.ciclovida

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.toggleable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel

// Colores de las filas del registro.
private val VerdeSubida = Color(0xFF2E7D32)
private val AmbarBajada = Color(0xFFFFB300)
private val AzulGuardado = Color(0xFF1565C0)

/**
 * La única pantalla de la app. Tiene dos paneles:
 *   - panel 1: cabecera + registro de eventos
 *   - panel 2: interruptor + contadores + botón de cerrar
 * FlowRow los pone lado a lado si caben (horizontal) o uno debajo del otro (vertical).
 *
 * OJO: se usa UN SOLO diseño para las dos orientaciones a propósito.
 * rememberSaveable reconoce cada valor guardado por su POSICIÓN en el código.
 * Si en vertical y en horizontal los contadores se llamaran desde sitios
 * distintos (por ejemplo, un if/else por orientación), el valor no se recuperaría.
 */
@Composable
fun PantallaCicloVida(idInstancia: String, alCerrarApp: () -> Unit) {
    // El interruptor también sobrevive a la rotación porque usa rememberSaveable.
    var mostrarSoluciones by rememberSaveable { mutableStateOf(false) }

    Surface(modifier = Modifier.fillMaxSize()) {
        FlowRow(
            modifier = Modifier
                .fillMaxSize()
                .safeDrawingPadding()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Panel 1
            Column(
                modifier = Modifier
                    .widthIn(min = 300.dp)
                    .weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Cabecera(idInstancia)
                SeccionRegistro()
            }
            // Panel 2
            Column(
                modifier = Modifier
                    .widthIn(min = 300.dp)
                    .weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                InterruptorSoluciones(
                    encendido = mostrarSoluciones,
                    alCambiar = { mostrarSoluciones = it }
                )
                SeccionContadores(mostrarSoluciones)
                BotonCerrar(alCerrarApp)
            }
        }
    }
}

// ---------------------------------------------------------------------------
// 1. Cabecera
// ---------------------------------------------------------------------------

@Composable
fun Cabecera(idInstancia: String) {
    Column {
        Text(
            text = "Ciclo de vida",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = "Instancia de la Activity: #$idInstancia",
            style = MaterialTheme.typography.titleMedium,
            fontFamily = FontFamily.Monospace
        )
    }
}

// ---------------------------------------------------------------------------
// 2. Registro de eventos
// ---------------------------------------------------------------------------

@Composable
fun SeccionRegistro() {
    // Lee la lista observable del objeto de nivel de proceso.
    val eventos = LogCicloVida.eventos

    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "Registro de eventos",
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.weight(1f)
                )
                OutlinedButton(onClick = { LogCicloVida.limpiar() }) {
                    Text("Limpiar registro")
                }
            }
            Text(
                text = "El más reciente está arriba.",
                style = MaterialTheme.typography.bodySmall
            )
            Spacer(modifier = Modifier.height(8.dp))

            if (eventos.isEmpty()) {
                Text(text = "(sin eventos)", style = MaterialTheme.typography.bodyMedium)
            }

            // Alto fijo con su propio scroll, para que no empuje los contadores.
            // Son 40 filas como máximo, así que basta una Column normal.
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(220.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                for (evento in eventos) {
                    FilaEvento(evento)
                }
            }
        }
    }
}

@Composable
fun FilaEvento(evento: EventoCicloVida) {
    // Color de fondo y de texto según el tipo de evento.
    val fondo = when (evento.tipo) {
        TipoEvento.SUBIDA -> VerdeSubida
        TipoEvento.BAJADA -> AmbarBajada
        TipoEvento.GUARDADO -> AzulGuardado
    }
    val colorTexto = when (evento.tipo) {
        TipoEvento.SUBIDA -> Color.White
        TipoEvento.BAJADA -> Color.Black
        TipoEvento.GUARDADO -> Color.White
    }

    Row(
        modifier = Modifier.padding(vertical = 2.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = evento.hora,
            fontFamily = FontFamily.Monospace,
            style = MaterialTheme.typography.bodyMedium
        )
        Spacer(modifier = Modifier.width(8.dp))
        Surface(color = fondo, shape = MaterialTheme.shapes.small) {
            Text(
                text = evento.nombre,
                color = colorTexto,
                fontWeight = FontWeight.Bold,
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
            )
        }
    }
}

// ---------------------------------------------------------------------------
// 3. Interruptor "Mostrar soluciones"
// ---------------------------------------------------------------------------

@Composable
fun InterruptorSoluciones(encendido: Boolean, alCambiar: (Boolean) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .toggleable(value = encendido, role = Role.Switch, onValueChange = alCambiar)
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = "Mostrar soluciones",
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.weight(1f)
        )
        // onCheckedChange = null porque el toque lo maneja toda la fila.
        Switch(checked = encendido, onCheckedChange = null)
    }
}

// ---------------------------------------------------------------------------
// 4. Contadores
// ---------------------------------------------------------------------------

@Composable
fun SeccionContadores(mostrarSoluciones: Boolean) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(text = "Contadores", style = MaterialTheme.typography.titleLarge)

        ContadorA()

        if (mostrarSoluciones) {
            ContadorB()
            ContadorC()
        }
    }
}

@Composable
fun ContadorA() {
    // PROBLEMA: remember guarda el valor solo mientras exista ESTA composición.
    // Al rotar se crea una Activity nueva (y una composición nueva): vuelve a 0.
    var n by remember { mutableIntStateOf(0) }

    TarjetaContador(
        titulo = "Contador A: remember (se pierde al rotar)",
        queSobrevive = "Rotar: se pierde / Proceso muerto: se pierde",
        valor = n,
        alSumar = { n++ },
        alReiniciar = { n = 0 }
    )
}

@Composable
fun ContadorB() {
    // SOLUCIÓN: rememberSaveable guarda el valor en el Bundle de onSaveInstanceState.
    // Sobrevive a la rotación y también a que el sistema mate el proceso.
    var n by rememberSaveable { mutableIntStateOf(0) }

    TarjetaContador(
        titulo = "Contador B: rememberSaveable",
        queSobrevive = "Rotar: sobrevive / Proceso muerto: sobrevive",
        valor = n,
        alSumar = { n++ },
        alReiniciar = { n = 0 }
    )
}

@Composable
fun ContadorC(contadorViewModel: ContadorViewModel = viewModel()) {
    // SOLUCIÓN: el valor vive en un ViewModel, que sobrevive a la rotación.
    // Pero vive en memoria: si el sistema mata el proceso, se pierde.
    TarjetaContador(
        titulo = "Contador C: ViewModel",
        queSobrevive = "Rotar: sobrevive / Proceso muerto: se pierde",
        valor = contadorViewModel.n,
        alSumar = { contadorViewModel.sumar() },
        alReiniciar = { contadorViewModel.reiniciar() }
    )
}

/** Dibujo común de los tres contadores (solo cambia de dónde sale el número). */
@Composable
fun TarjetaContador(
    titulo: String,
    queSobrevive: String,
    valor: Int,
    alSumar: () -> Unit,
    alReiniciar: () -> Unit
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(12.dp)) {
            Text(text = titulo, style = MaterialTheme.typography.titleMedium)
            Text(text = queSobrevive, style = MaterialTheme.typography.bodySmall)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = valor.toString(),
                    fontSize = 48.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f)
                )
                Button(onClick = alSumar) {
                    Text("+1")
                }
                Spacer(modifier = Modifier.width(8.dp))
                OutlinedButton(onClick = alReiniciar) {
                    Text("Reiniciar")
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// 5. Cerrar la app
// ---------------------------------------------------------------------------

@Composable
fun BotonCerrar(alCerrarApp: () -> Unit) {
    Button(
        onClick = alCerrarApp,
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.error,
            contentColor = MaterialTheme.colorScheme.onError
        ),
        modifier = Modifier.fillMaxWidth()
    ) {
        Text("Cerrar la app (finish)")
    }
}
