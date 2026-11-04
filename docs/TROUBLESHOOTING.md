# Solución de problemas

**macOS bloquea la descarga.** Revisa la procedencia, hashes y firma ad hoc. Sigue [Instalación](INSTALL.md) y el procedimiento oficial de Apple; no desactives protecciones globales.

**La app dice que ya está abierta.** Otra instancia usa la misma carpeta. Ciérrala normalmente. El bloqueo es del sistema y se libera al terminar el proceso; no borres la base ni la reemplaces. Si sigue ocurriendo, reinicia la sesión y registra una incidencia sin adjuntar datos.

**No veo las finanzas de una edición anterior.** La publicación y Dev comienzan separadas. No se importa la edición personal automáticamente. Consulta [Datos](DATA.md); no cambies application_id ni copies archivos activos.

**El saldo no coincide con ingresos menos gastos.** Los saldos iniciales, principal devuelto y préstamos recibidos explican la diferencia. Transferencias y reservas no son gastos. Revisa la explicación de Informes y los registros del mes.

**Una cuota no se puede guardar.** Introduce principal explícito, menor o igual al pago y a la deuda pendiente. Revisa pagos posteriores si estás editando uno anterior. La app no calcula intereses automáticamente.

**No puedo reservar más ahorro.** Las reservas nuevas deben caber en el saldo disponible y en el objetivo. Una reserva no crea dinero.

**La restauración se rechaza.** Puede ser de otra aplicación, de otro esquema, superar 100 MB o fallar integridad/reglas. Conserva el original, no modifiques sus metadatos para forzarlo. La base actual no debe reemplazarse por una copia rechazada.

**Las pruebas UI fallan en CI o por SSH.** WebKit/AppKit necesitan una sesión gráfica. Conserva el informe/log de prueba aislado y comprueba el entorno. No marques la prueba como superada por omitirla.

**Legibilidad o efectos.** En Ajustes elige Claro/Oscuro/Sistema. Las opciones de accesibilidad de macOS reducen efectos. No hay auditoría completa de VoiceOver ni promesa de accesibilidad universal.
