# Seguimiento público

## 2026-11-04 · Presentación para revisión de ingeniería

Los README español/inglés enlazan el caso técnico del perfil S3rri-dev, con modelo financiero, invariantes, arquitectura y rutas de revisión. Se actualizan descripción, temas y enlace de descarga del repositorio. No cambia la implementación ni se reemplazan los paquetes de la release.

Se repitieron compilación ARM64, 52 comprobaciones de datos, 64 de interfaz nativa WebKit (20 capturas), 11 de aislamiento y auditoría de fuentes/bundle: correctas. Se mantienen los límites de compatibilidad y firma de la publicación.

Actualización del estado remoto: CI 41842987922 terminó globalmente como failure; ambos trabajos quedaron cancelled, sin ejecutar pasos. Las anotaciones de GitHub indican falta de capacidad de runners macOS y ausencia de adquisición de los trabajos. No se declara CI superada. La actualización documental usa skip ci para no encolar de nuevo compilaciones de código sin cambios.

## 2026-11-04 · Preparación de 0.4.0

Se prepara la primera publicación pública de Caudal a partir de la edición local, en una copia independiente. Se preservan la aplicación personal, sus datos y los proyectos de referencia.

Realizado: separación de identificadores/directorios pública y Dev, arranque vacío, fondo vectorial original, GPL-3.0-or-later con política de identidad, guías español/inglés, portada, capturas reales con datos ficticios y plantillas de colaboración. Las reglas financieras siguen separando céntimos, transferencias, principal/intereses y reservas.

Ejecutadas 52 comprobaciones de datos, 64 de UI WebKit y 11 de aislamiento, todas correctas. Revisión nativa: primer arranque, formulario visible, cuenta ficticia, selectores de exportación, vista previa/restauración y temas claro/oscuro. Auditoría de fuente/bundle y validaciones de firma/plist correctas.

La evidencia y los límites se registran en docs/VERIFICACION.md. Firma ad hoc, sin Developer ID ni notarización. Publicada v0.4.0 en https://github.com/S3rri-dev/caudal/releases/tag/v0.4.0 con app ZIP, DMG, fuentes del commit etiquetado, manifiesto y SHA256SUMS. Borrador revisado; descarga pública sin autenticación HTTP 200, hashes correctos, DMG de solo lectura y ventana nativa vacía/formulario comprobados. CI macOS 15/26 aún en cola: no declarada superada. Paquetes de compilación local comprobada; fuentes personales, app instalada y datos originales intactos.
