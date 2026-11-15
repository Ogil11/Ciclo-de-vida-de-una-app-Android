# Explicación del código

Esta guía es para quien sabe programar pero no conoce Android. Recorre los cuatro archivos Kotlin de la app y explica qué hace cada parte y por qué.

En el código hay tres comentarios que marcan las ideas clave. Puedes buscarlos con Ctrl+F:

| Marca | Dónde | Idea |
|---|---|---|
| `// CICLO DE VIDA:` | `MainActivity.kt` | Cada callback que Android llama a la Activity. |
| `// PROBLEMA:` | `PantallaCicloVida.kt`, contador A | `remember` pierde el valor al rotar. |
| `// SOLUCIÓN:` | `PantallaCicloVida.kt` (contador B) y `ContadorViewModel.kt` (contador C) | Dos formas de conservar el valor. |

Todos los archivos están en `app/src/main/java/com/demo/ciclovida/`.

---

## 1. `MainActivity.kt`: la Activity y sus callbacks

Una **Activity** es una pantalla de la app. Nosotros no la creamos con `new`: la crea Android y le avisa de cada cambio llamando a unos métodos llamados **callbacks**. Para ver esos avisos, la clase `MainActivity` sobrescribe (`override`) cada callback.

Todos siguen **el mismo patrón**, para explicarlo una sola vez:

```kotlin
override fun onStart() {
    super.onStart()        // 1. llamar a la versión de Android (obligatorio)
    registrar("onStart")   // 2. anotarlo en la pantalla y en Logcat
}
```

`registrar(...)` (línea 84) solo reenvía el texto a `LogCicloVida.registrar(...)`.

### Los callbacks, en orden de aparición

| Callback | Línea | Cuándo lo llama Android | En la demo |
|---|---|---|---|
| `onCreate` | 18 | La Activity **se crea**. Aquí se construye la interfaz con `setContent`. | Al abrir la app y **después de rotar**. |
| `onStart` | 37 | La Activity **se vuelve visible**. | Al abrir, al volver de Recientes, tras rotar. |
| `onResume` | 43 | La Activity pasa a **primer plano** y recibe toques. | Igual que `onStart`, justo después. |
| `onPause` | 49 | Deja de estar en primer plano. Es el primer aviso de que se va. | Inicio, rotar, Atrás. |
| `onStop` | 55 | **Ya no es visible.** | Inicio, rotar, Atrás. |
| `onRestart` | 61 | Vuelve a mostrarse **después de un `onStop`**, sin haberse destruido. | Al volver desde Recientes. Es la señal de que *no* hubo `onCreate`. |
| `onSaveInstanceState` | 68 | Android **guarda el estado pequeño** de la pantalla en un `Bundle`, por si tiene que recrearla. | Inicio y rotar (no al pulsar Atrás, porque la Activity ya no volverá). |
| `onDestroy` | 76 | La Activity **se destruye**. | Rotar, Atrás, `finish()`. |

### `onDestroy` dice el motivo

```kotlin
val rotacion = if (isChangingConfigurations) "sí" else "no"
val terminada = if (isFinishing) "sí" else "no"
registrar("onDestroy (rotación: $rotacion, finish: $terminada)")
```

- `isChangingConfigurations` es `true` si se destruye por un **cambio de configuración**, como rotar. Android creará otra Activity enseguida.
- `isFinishing` es `true` si se destruye porque **terminó**: el usuario pulsó Atrás o el código llamó a `finish()`.

### El identificador de instancia (línea 24)

```kotlin
val idInstancia = "%04X".format(hashCode() and 0xFFFF)
```

`hashCode()` es distinto para cada objeto. Nos quedamos con sus 4 últimos dígitos hexadecimales. Al rotar, Android crea **otro objeto** `MainActivity` y el número cambia. Así se ve que la Activity es nueva.

### `setContent` (línea 26)

Conecta la Activity con la interfaz de Compose: dibuja `PantallaCicloVida(...)` dentro del tema de Material 3. Le pasa el identificador y una función `{ finish() }` para el botón de cerrar.

---

## 2. `LogCicloVida.kt`: el registro de eventos

```kotlin
object LogCicloVida {            // línea 29
    val eventos = mutableStateListOf<EventoCicloVida>()   // línea 37
    fun registrar(nombre: String) { ... }                 // línea 40
    fun limpiar() { ... }                                 // línea 53
}
```

- En Kotlin, un **`object`** es una clase con **una única instancia** para toda la app. Vive mientras viva el **proceso**, no la Activity. Por eso el registro **no se borra al rotar**: la Activity se destruye, pero el proceso sigue vivo. Si el sistema mata el proceso, el registro sí se pierde, como se ve en el bonus.
- **`mutableStateListOf`** es una lista *observable* de Compose. Cuando se añade un elemento, Compose se entera y vuelve a dibujar la pantalla sola.
- `registrar` añade el evento en la posición 0 (arriba), borra los que pasen de 40 y escribe el texto en **Logcat** con `Log.d("CicloVida", ...)`.
- `tipoDe(nombre)` clasifica el evento como `SUBIDA`, `BAJADA` o `GUARDADO`. Eso solo sirve para elegir el color de la fila.

---

## 3. `ContadorViewModel.kt`: el estado del contador C

```kotlin
class ContadorViewModel : ViewModel() {
    var n by mutableIntStateOf(0)
        private set
    fun sumar() { n++ }
    fun reiniciar() { n = 0 }
}
```

Un **ViewModel** es un objeto que guarda datos de una pantalla, pero vive **fuera de la Activity**. Android lo guarda aparte y, cuando rota, le entrega **el mismo ViewModel** a la Activity nueva. Por eso C conserva su valor al rotar.

Este ViewModel **no usa `SavedStateHandle`** (el mecanismo para que un ViewModel guarde datos en el `Bundle`), y es a propósito. El ViewModel solo existe en la memoria del proceso. Si el sistema mata el proceso, desaparece y C vuelve a 0.

`mutableIntStateOf` hace que el número sea *observable*: al cambiar `n`, Compose redibuja la tarjeta.

---

## 4. `PantallaCicloVida.kt`: la interfaz

En **Jetpack Compose** la interfaz se escribe con funciones Kotlin marcadas con `@Composable`. Cada función describe un trozo de pantalla. Cuando cambia un estado que la función lee, Compose la vuelve a ejecutar: eso es la **recomposición**.

### Estructura

| Función | Línea | Qué dibuja |
|---|---|---|
| `PantallaCicloVida` | 60 | La pantalla completa: dos paneles dentro de un `FlowRow`. |
| `Cabecera` | 107 | Título e identificador de instancia. |
| `SeccionRegistro` | 127 | Tarjeta con el registro, el botón "Limpiar registro" y la lista con scroll propio. |
| `FilaEvento` | 170 | Una fila: hora y nombre del evento sobre su color. |
| `InterruptorSoluciones` | 210 | El interruptor "Mostrar soluciones". |
| `SeccionContadores` | 233 | El contador A siempre, y B y C solo si el interruptor está encendido. |
| `ContadorA` / `ContadorB` / `ContadorC` | 247 / 262 / 277 | Cada uno con su forma de guardar el número. |
| `TarjetaContador` | 291 | El dibujo común: número grande, "+1" y "Reiniciar". |
| `BotonCerrar` | 326 | Botón rojo que llama a `finish()`. |

### Los tres contadores

Los tres usan la misma `TarjetaContador`. Lo único que cambia es **dónde se guarda el número**.

**Contador A, `remember` (línea 250): `// PROBLEMA:`**

```kotlin
var n by remember { mutableIntStateOf(0) }
```

`remember` guarda el valor **en la composición**, es decir, en el árbol de interfaz que Compose mantiene para *esta* Activity. Al rotar, la Activity se destruye y con ella su composición. La Activity nueva empieza una composición nueva y `n` vuelve a 0.

**Contador B, `rememberSaveable` (línea 265): `// SOLUCIÓN:`**

```kotlin
var n by rememberSaveable { mutableIntStateOf(0) }
```

Hace lo mismo que `remember`, pero además **escribe el valor en el `Bundle`** que Android guarda en `onSaveInstanceState`. Al recrear la Activity, Compose lo lee de vuelta. Ese `Bundle` lo conserva el sistema, **fuera del proceso**, así que el valor sobrevive a la rotación *y* a la muerte del proceso. A cambio, solo admite datos pequeños y guardables: números, textos, etc.

**Contador C, `ViewModel` (línea 277): `// SOLUCIÓN:`**

```kotlin
fun ContadorC(contadorViewModel: ContadorViewModel = viewModel()) { ... }
```

`viewModel()` pide a Android el `ContadorViewModel` de esta Activity. La primera vez lo crea; tras rotar, devuelve **el mismo objeto**. Sobrevive a la rotación, pero no a la muerte del proceso.

### Resumen: qué sobrevive a qué

| | Rotar | Proceso muerto | Dónde vive el valor |
|---|---|---|---|
| A `remember` | ❌ se pierde | ❌ se pierde | Composición de la Activity |
| B `rememberSaveable` | ✅ sobrevive | ✅ sobrevive | `Bundle` de `onSaveInstanceState` |
| C `ViewModel` | ✅ sobrevive | ❌ se pierde | Memoria del proceso, fuera de la Activity |

### Un detalle importante: un solo diseño para las dos orientaciones

`rememberSaveable` identifica cada valor guardado por su **posición en el código** (en qué función y en qué orden se llamó). Si la pantalla usara un `if (horizontal) {...} else {...}` y llamara a `ContadorB()` desde dos sitios distintos, al rotar la posición cambiaría y **el valor no se recuperaría**.

Por eso `PantallaCicloVida` usa **un único diseño**: un `FlowRow` con dos paneles. Si caben, los pone lado a lado (horizontal); si no, uno debajo del otro (vertical). Las llamadas a los contadores están siempre en el mismo sitio.

### El interruptor

```kotlin
var mostrarSoluciones by rememberSaveable { mutableStateOf(false) }   // línea 62
```

También usa `rememberSaveable`, así que sigue encendido después de rotar o de que muera el proceso.

Nota: cuando se **apaga** el interruptor, B y C dejan de dibujarse. B pierde su valor en ese momento, porque `rememberSaveable` solo guarda lo que está en pantalla. C no, porque su ViewModel sigue vivo.

---

## 5. Otros archivos

| Archivo | Para qué sirve |
|---|---|
| `app/src/main/AndroidManifest.xml` | Declara la app y su única Activity como pantalla de inicio (`LAUNCHER`). No pide permisos. No declara `android:configChanges`, así que al rotar Android recrea la Activity, que es lo que queremos mostrar. |
| `app/build.gradle.kts` | Configuración del módulo: paquete `com.demo.ciclovida`, `minSdk` 26, `compileSdk`/`targetSdk` 35, Compose y dependencias. |
| `gradle/libs.versions.toml` | Versiones de las librerías, en un solo sitio. |
| `settings.gradle.kts` | Repositorios de descarga, incluido el espejo de Maven Central. |
| `scripts/*.sh` | Automatizan la demo. Ver el README. |

---

## Glosario

| Término | Significado |
|---|---|
| **Activity** | Una pantalla de una app Android. La crea y destruye el sistema, no nuestro código. |
| **Callback** | Método nuestro que *otro* (aquí, Android) llama cuando ocurre algo: `onCreate`, `onPause`, etc. |
| **Ciclo de vida** | Secuencia de estados por los que pasa una Activity (creada, visible, en primer plano, detenida, destruida) y los callbacks que marcan cada cambio. |
| **Configuración** | Características del dispositivo que afectan a la interfaz: orientación, tamaño de pantalla, idioma, modo oscuro… Si cambia, Android por defecto **destruye y recrea** la Activity. |
| **Recomposición** | Cuando cambia un estado, Compose vuelve a ejecutar las funciones `@Composable` que lo leen para actualizar la pantalla. |
| **`remember`** | Guarda un valor entre recomposiciones, pero se pierde si se destruye la composición (al rotar). |
| **`rememberSaveable`** | Como `remember`, pero además guarda el valor en el `Bundle` del estado de la instancia. Sobrevive a la rotación y a la muerte del proceso. |
| **`Bundle`** | Contenedor clave-valor pequeño que Android guarda por nosotros en `onSaveInstanceState`. |
| **ViewModel** | Objeto que guarda el estado de una pantalla fuera de la Activity. Sobrevive a la rotación, pero vive en memoria: muere con el proceso. |
| **Proceso** | El programa en ejecución de la app en Linux/Android. Android puede **matarlo** cuando la app está en segundo plano y falta memoria. |
| **Logcat** | El registro de mensajes del sistema Android. Se ve con `adb logcat` o en Android Studio. Aquí filtramos por el tag `CicloVida`. |
| **adb** | *Android Debug Bridge*: herramienta de línea de comandos para controlar un emulador o un teléfono (instalar apps, pulsar teclas, rotar, ver Logcat…). |
| **AVD** | *Android Virtual Device*: la configuración de un emulador (modelo, versión de Android, RAM). |
