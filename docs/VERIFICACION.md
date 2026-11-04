# Verificación · Caudal 0.4.0

Fecha: 2026-11-04, Europe/Madrid. Compilación 5. Ejecución local en Mac ARM64 con macOS 27.0.1 y Apple Swift 6.4. No se descargaron dependencias de aplicación.

## Resultados ejecutados

| Comprobación | Resultado |
| --- | --- |
| ./scripts/build.sh | Compilación ARM64 y firma ad hoc correctas |
| ./tests/run.sh | 52 comprobaciones de datos superadas |
| ./tests/run-ui.sh | 64 comprobaciones en WebKit real superadas; 20 capturas |
| ./tests/isolation.sh | 11 comprobaciones de identidad, arranque e independencia pública/Dev superadas |
| Auditoría de fuentes y bundle | Sin patrones de credenciales, rutas personales o artefactos financieros detectados |
| codesign --verify --deep --strict y plutil -lint | Correctos |

Informe de la primera ejecución y galería: `build/ui-20261104-145041/ui-result.json`; build/ no se publica. La compilación final ligada al commit repitió los mismos resultados; informe UI final: `build/ui-20261104-145756/ui-result.json`. Las capturas seleccionadas de docs/images/ son de esa ejecución y contienen exclusivamente datos ficticios. La portada es una composición promocional identificada como tal.

Las 52 comprobaciones cubren céntimos, transferencias, deuda inicial/nuevas disposiciones, cuotas con principal e intereses, presupuestos, reservas, edición/borrado/deshacer, errores, CSV, copias, rechazos de restauración y persistencia. Las 64 de UI guardan formularios reales, verifican cifras, búsqueda, meses, ocho vistas, temas persistidos, accesibilidad simulada y ventana mínima. Las 11 de aislamiento comprueban bundles distintos y bases separadas.

## Revisión nativa por herramientas de ordenador

Se comprobó el primer arranque vacío de la edición pública y la apertura/cancelación del formulario de cuenta, sin crear datos financieros en su directorio por defecto.

En una carpeta de prueba aislada se creó desde la interfaz una cuenta ficticia de 1000,00 €, se exportaron SQLite y CSV mediante selectores nativos, se seleccionó la copia, se revisó su vista previa (1 cuenta, 0 movimientos/deudas/objetivos) y se confirmó su restauración. Se mostró el aviso de copia previa conservada y el historial de restauración. Se verificaron visualmente los temas oscuro y claro; el diálogo se dibuja correctamente. Una reapertura del almacén con --check conservó 1 cuenta y exactamente 100000 céntimos, sin ingresos ficticios.

Las exportaciones de prueba son temporales y no se incluyen en Git. La edición personal instalada, sus datos, sus fuentes y el proyecto de referencia se conservan; no se importan a la copia pública.

## Diseño, licencias y privacidad

Fondo vectorial original sustituye la fotografía cuyo permiso de redistribución no está acreditado. Nombre/logo se conservan bajo política de identidad separada de la GPL. Licencia íntegra y avisos están incluidos en el bundle y la distribución.

Contraste de tokens sobre referencias densas: principal 12,67:1 claro / 15,88:1 oscuro; secundario 7,77:1 / 10,79:1; botón 6,54:1. No es una auditoría WCAG de todos los píxeles transparentes. Las preferencias de accesibilidad se simularon sin cambiar las globales del Mac.

## Distribución y automatización

Release pública: https://github.com/S3rri-dev/caudal/releases/tag/v0.4.0. Repositorio publicado exclusivamente por S3rri-dev; identidad, autoría noreply y permisos ADMIN comprobados. Issues, Discussions y reporte privado de vulnerabilidades habilitados. Las acciones están fijadas por SHA y CI tiene permisos de lectura.

Fuentes de la aplicación y paquetes: commit `e84e37c17adafcbf8a2a54e953609e65b63e7136`, etiqueta `v0.4.0`. El ZIP de fuentes descargado coincide archivo por archivo con los 72 archivos del commit; el ZIP de aplicación, DMG y build contienen el mismo bundle por SHA-256. Esta actualización documental posterior no cambia los paquetes etiquetados.

Se revisó el borrador antes de publicarlo. Se descargaron sus cinco adjuntos y se verificaron SHA-256, avisos, acceso a Aplicaciones y arranque vacío aislado desde el DMG montado en solo lectura. Tras publicar, se descargaron otra vez los cinco adjuntos con curl sin autenticación, sin cookies y sin cabecera Authorization: **HTTP 200 en los cinco**, hashes correctos. Se montó la descarga pública en solo lectura (comprobado también con diskutil), se verificó la firma y se abrió la ventana nativa con una base nueva aislada. Se comprobó visualmente el resumen vacío y el formulario de primera cuenta; después se cerró la app y expulsó el volumen.

| Adjunto | SHA-256 |
| --- | --- |
| Caudal-0.4.0-arm64.dmg | `a7b2c30d9571d153dcf9d8a693f9e9654444265a88e24048bcc145f03e002fa1` |
| Caudal-0.4.0-arm64-app.zip | `726c5e52676b7a2045cbe82813f43804084e8533941ffef5292dcdb5915e43e7` |
| Caudal-0.4.0-src.zip | `1965ecb5d4058b3538302101ea2ef421658e1e42c9ccf410b017f63acafa727b` |

Manifiesto y SHA256SUMS.txt completan los hashes y describen arquitectura, compilador y procedencia **local verified build**. Los binarios no proceden de Actions.

**CI remota sin ejecución:** la ejecución https://github.com/S3rri-dev/caudal/actions/runs/41842987922 terminó con resultado global failure; los trabajos macOS 15 y 26 quedaron cancelled sin ejecutar pasos. Las anotaciones de GitHub indican que los trabajos no fueron adquiridos por un ejecutor hosted y restricciones de capacidad macOS ARM64. No se declara superada ni se atribuyen pruebas ejecutadas en esas versiones. El workflow manual de releases está preparado; no se afirma haberlo ejecutado para generar esta publicación.

El escaneo de archivos, historial y binario no detectó patrones de rutas personales, credenciales o datos financieros empaquetados. Se revisaron los 56 enlaces locales Markdown, la procedencia de recursos y las imágenes; las 11 imágenes/badges del README cargaron en navegador. Las huellas de fuentes originales, app personal instalada y contenido lógico de bases personales/de referencia se mantuvieron idénticas.

## Revisión del escaparate — 4 de noviembre de 2026

Se añadieron enlaces desde los README español/inglés al caso técnico de S3rri-dev. Se repitieron scripts/build.sh, tests/run.sh (52), tests/run-ui.sh (64 y 20 capturas), tests/isolation.sh (11) y auditoría del bundle, con resultado correcto. Esta actualización es documental: no cambia el código, los datos, los identificadores ni los paquetes de la release. La interfaz revisada de la presentación es GitHub; no se atribuyen nuevas pruebas físicas en otros Mac.

## Límites

Firma ad hoc; sin Developer ID ni notarización. Objetivo mínimo macOS 13, únicamente macOS 27.0.1 comprobado localmente. Sin prueba en otro Mac limpio, cuarentena de navegador, Intel, auditoría externa, grandes históricos, VoiceOver completo o validación de uso diario por terceros. Las pruebas internas no acreditan resultados de uso de una persona.
