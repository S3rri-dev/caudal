# Permisos

No se solicita acceso a contactos, calendario, micrófono, cámara, ubicación, bancos, accesibilidad del sistema o captura de pantalla para usar Caudal.

La aplicación crea su carpeta de datos en Application Support y utiliza selectores nativos para exportar y restaurar archivos. macOS puede pedir acceso a una carpeta protegida que selecciones. No requiere permisos de administrador, auxiliares privilegiados o acceso completo al disco.

Caudal lee las preferencias de accesibilidad de macOS para reducir transparencia/movimiento o aumentar contraste. No las cambia y esto no equivale a solicitar el permiso de Accesibilidad.

La aplicación distribuida no está aislada con App Sandbox. La ausencia de permisos solicitados no es una garantía de aislamiento del proceso; revisa el código y el origen del binario.

Los modos de prueba y capturas automatizadas solo funcionan con CAUDAL_DATA y --ui-test. Son herramientas de desarrollo, no una función de captura de las finanzas personales.
