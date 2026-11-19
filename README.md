# Ciclo de vida de una app Android

Demo en Kotlin y Jetpack Compose que muestra qué le pasa a una app Android cuando el usuario la minimiza, la rota o la cierra, y cómo evitar perder datos.

## Video de la exposición

https://youtu.be/Rbz3YqVUN-E

## Qué muestra

- Los callbacks del ciclo de vida (`onCreate`, `onStart`, `onResume`, `onPause`, `onStop`, `onRestart`, `onSaveInstanceState`, `onDestroy`) en un registro en pantalla y en Logcat.
- Qué pasa con el estado al rotar el teléfono, con tres contadores:
  - **A:** `remember` (se pierde al rotar).
  - **B:** `rememberSaveable` (sobrevive a la rotación y a la muerte del proceso).
  - **C:** `ViewModel` (sobrevive a la rotación, pero no a la muerte del proceso).

## Contenido del repositorio

- [`ciclovida-demo/`](ciclovida-demo/): el proyecto de Android Studio.
- `Ciclo de vida de una app Android.pptx` y `.pdf`: la presentación.

## Cómo correrlo en Android Studio

1. Abre la carpeta `ciclovida-demo` con *File → Open* y espera a que termine el Gradle Sync.
2. Crea un emulador Pixel con Android 14 (API 34) en *Device Manager*.
3. Selecciona el módulo `app` y el emulador, y pulsa Run.
4. Para ver los eventos en Logcat, filtra por `tag:CicloVida`.

El guion completo de la demo está en [`ciclovida-demo/README.md`](ciclovida-demo/README.md).

## Autores

Oscar Gil y Jean Marthe.
