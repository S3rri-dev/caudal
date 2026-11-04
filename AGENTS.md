# Caudal

- Trabajar en español; ser directo y preciso. Proyecto independiente de otras aplicaciones.
- Leer README.md, docs/ESPECIFICACION.md y docs/VERIFICACION.md antes de ampliar alcance.
- macOS Apple Silicon, Swift/AppKit/WebKit y SQLite del sistema. Sin servidor, red, cuentas de acceso ni dependencias descargadas para la aplicación.
- Código GPL-3.0-or-later; identidad según TRADEMARKS.md. No añadir materiales sin procedencia y permisos documentados.
- La edición pública empieza vacía. Solo datos ficticios en tests, ejemplos e imágenes. Nunca publicar bases, copias, credenciales, rutas personales ni registros privados.
- Edición pública: io.github.s3rri-dev.caudal, Application Support/Caudal. Desarrollo: io.github.s3rri-dev.caudal.dev, Application Support/Caudal Dev. CAUDAL_DATA solo para pruebas aisladas.
- Importes en céntimos enteros; separar transferencia, ingreso, gasto, principal, intereses y reservas de ahorro. Validar en Store, no solo en la interfaz.
- Español, EUR, Europe/Madrid; no registrar movimientos futuros como efectuados. No inferir pagos por el calendario.
- SQLite con migraciones versionadas, transacciones, claves foráneas, copias consistentes y vista previa antes de restaurar. Datos fuera del bundle.
- Ejecutar ./scripts/build.sh, ./tests/run.sh, ./tests/run-ui.sh y python3 scripts/audit_publication.py --bundle dist/Caudal.app. Revisar la ventana nativa en sesión gráfica y documentar evidencia real.
- No reintroducir animaciones de opacidad/transformación ni desenfoques superpuestos en los diálogos de WebKit: comprobar composición nativa.
- No afirmar Developer ID, notarización, auditoría externa, compatibilidad con otras plataformas o CI superada sin evidencia.
- Actualizar SEGUIMIENTO.md y docs/VERIFICACION.md. No delegar a subagentes sin petición explícita.
