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

El informe UI local está en `build/ui-20261104-145041/ui-result.json`; build/ no se publica. Las capturas seleccionadas de docs/images/ son de esa ejecución y contienen exclusivamente datos ficticios. La portada es una composición promocional identificada como tal.

Las 52 comprobaciones cubren céntimos, transferencias, deuda inicial/nuevas disposiciones, cuotas con principal e intereses, presupuestos, reservas, edición/borrado/deshacer, errores, CSV, copias, rechazos de restauración y persistencia. Las 64 de UI guardan formularios reales, verifican cifras, búsqueda, meses, ocho vistas, temas persistidos, accesibilidad simulada y ventana mínima. Las 11 de aislamiento comprueban bundles distintos y bases separadas.

## Revisión nativa por herramientas de ordenador

Se comprobó el primer arranque vacío de la edición pública y la apertura/cancelación del formulario de cuenta, sin crear datos financieros en su directorio por defecto.

En una carpeta de prueba aislada se creó desde la interfaz una cuenta ficticia de 1000,00 €, se exportaron SQLite y CSV mediante selectores nativos, se seleccionó la copia, se revisó su vista previa (1 cuenta, 0 movimientos/deudas/objetivos) y se confirmó su restauración. Se mostró el aviso de copia previa conservada y el historial de restauración. Se verificaron visualmente los temas oscuro y claro; el diálogo se dibuja correctamente. Una reapertura del almacén con --check conservó 1 cuenta y exactamente 100000 céntimos, sin ingresos ficticios.

Las exportaciones de prueba son temporales y no se incluyen en Git. La edición personal instalada, sus datos, sus fuentes y el proyecto de referencia se conservan; no se importan a la copia pública.

## Diseño, licencias y privacidad

Fondo vectorial original sustituye la fotografía cuyo permiso de redistribución no está acreditado. Nombre/logo se conservan bajo política de identidad separada de la GPL. Licencia íntegra y avisos están incluidos en el bundle y la distribución.

Contraste de tokens sobre referencias densas: principal 12,67:1 claro / 15,88:1 oscuro; secundario 7,77:1 / 10,79:1; botón 6,54:1. No es una auditoría WCAG de todos los píxeles transparentes. Las preferencias de accesibilidad se simularon sin cambiar las globales del Mac.

## Distribución y automatización

El empaquetado se liga al commit declarado en Info.plist y al manifiesto. Los resultados de descarga, montaje y lanzamiento del paquete se añadirán tras la comprobación de la release. En este punto no se declara CI remota superada ni descarga pública comprobada.

## Límites

Firma ad hoc; sin Developer ID ni notarización. Objetivo mínimo macOS 13, únicamente macOS 27.0.1 comprobado localmente. Sin prueba en otro Mac limpio, cuarentena de navegador, Intel, auditoría externa, grandes históricos, VoiceOver completo o validación de uso diario por terceros. Las pruebas internas no acreditan resultados de uso de una persona.
