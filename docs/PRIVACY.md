# Privacidad

Caudal funciona localmente. No crea cuentas de acceso, no incluye analítica, anuncios ni telemetría, y la interfaz no realiza peticiones de red. No accede a tus bancos, correo, contactos, calendarios o inversiones.

Los registros y el historial local están en una base SQLite fuera de la app. Las copias contienen los mismos datos sensibles que la base. No tienen cifrado propio ni contraseña de Caudal. La protección del disco y de la sesión depende de macOS y tu configuración. Se crean carpetas con permisos 0700 y archivos de datos con 0600.

El historial registra cambios y puede conservar datos anteriores al editar o eliminar. El borrado de un movimiento es lógico para permitir deshacer; no es un borrado criptográfico. Las copias previas pueden conservar registros eliminados.

Exportar usa el selector nativo y escribe donde tú eliges. Si seleccionas una carpeta sincronizada por otro servicio, ese servicio puede subir el archivo; Caudal no controla ese destino. Las copias automáticas locales no se podan en esta versión: revisa su espacio y conservación.

La app usa un almacén WebKit no persistente para la interfaz y recursos del bundle. CSP bloquea conexiones de red y la navegación se limita a los archivos web del paquete. No incorpora un actualizador ni sincronización.

Publicar una incidencia o Discussion en GitHub es una acción externa del usuario. No adjuntes bases, extractos, saldos reales ni capturas privadas. Usa datos ficticios al pedir ayuda.
