# Instalar Caudal

## Requisitos y descarga

Mac con Apple Silicon. Objetivo de compilación macOS 13 o posterior; la compatibilidad realmente comprobada se registra en VERIFICACION.md. No hay binario Intel, Windows, iPhone ni paquete Homebrew.

Descarga el DMG o ZIP de la aplicación desde https://github.com/S3rri-dev/caudal/releases/latest. Verifica los hashes con SHA256SUMS.txt, descargado de la misma release:

```sh
shasum -a 256 -c SHA256SUMS.txt
```

Ese comando requiere todos los adjuntos enumerados en la misma carpeta. Para comprobar solo el DMG, calcula `shasum -a 256 Caudal-0.4.0-arm64.dmg` y compara con la línea correspondiente del archivo. Los hashes detectan cambios en los archivos; no sustituyen una firma de desarrollador.

Monta el DMG, arrastra Caudal.app a Aplicaciones y expulsa el volumen. El ZIP conserva el bundle .app y puede extraerse con Utilidad de Compresión. Si ya tienes una edición personal llamada Caudal.app, conserva ambas en carpetas diferentes para evitar sustituirla: los nombres visibles coinciden aunque sus identificadores y datos sean distintos.

## Primer arranque y firma

La firma es ad hoc. No existe certificado Developer ID ni notarización de Apple. macOS puede impedir la apertura de un archivo descargado. Revisa su origen y, si confías en esta release, sigue el procedimiento de Apple en Ajustes del Sistema → Privacidad y seguridad → Abrir igualmente. No desactives Gatekeeper ni elimines la cuarentena de todo el sistema.

Guía oficial: https://support.apple.com/es-es/102445. Una app bloqueada por política de una organización puede requerir intervención de su administrador. No se garantiza que todos los sistemas permitan la excepción.

La prueba local del paquete no equivale a una instalación desde un Mac limpio con cuarentena aplicada por un navegador.

## Actualizar y desinstalar

Cierra la app, exporta una copia completa y sustituye solo el bundle de la edición pública. Los datos están fuera de él. Eliminar la app no elimina la carpeta de datos. Para borrar datos, haz primero una copia y verifica manualmente la carpeta indicada en Ajustes y datos. No se proporciona un borrado automático.
