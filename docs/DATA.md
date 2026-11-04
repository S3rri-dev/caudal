# Almacenamiento, copias y restauración

| Edición | Bundle ID | Carpeta en Application Support |
| --- | --- | --- |
| Caudal pública | io.github.s3rri-dev.caudal | Caudal |
| Caudal Dev | io.github.s3rri-dev.caudal.dev | Caudal Dev |

En cada carpeta: `caudal.sqlite`, su WAL/SHM si la base está abierta, `apariencia.json`, `instance.lock` y `Copias/`. El esquema comienza en versión 1 y usa application_id 1128355121. El identificador SQLite es distinto del de la edición personal previa. No hay importación automática desde esa edición o desde otra app. No pruebes sobre una base personal ni copies una base activa a mano.

CAUDAL_DATA sustituye expresamente el directorio para pruebas. FINANZAS_DATA no se usa. Si apuntas manualmente dos procesos a la misma carpeta, el bloqueo exclusivo impide abrir una segunda interfaz. Las ediciones pública y Dev pueden compartir voluntariamente una copia exportada compatible, pero sus directorios por defecto son diferentes.

## Qué guarda

Cuentas y saldos iniciales; categorías; movimientos con céntimos enteros; deudas; presupuestos mensuales; objetivos/reservas; historial y versión de esquema. La apariencia es un JSON independiente y no se restaura con SQLite.

- Transferencia: salida y entrada compensadas, sin ingreso/gasto.
- Préstamo recibido: suben saldo y principal, sin ingreso.
- Pago de deuda: baja el saldo por el total; baja la deuda solo por el principal; diferencia = gasto de intereses/comisiones.
- Ahorro: asignación virtual del saldo, sin movimiento de cuenta.
- Variación mensual = ingresos − gastos − principal amortizado + préstamos recibidos.

Los saldos iniciales no tienen fecha de apertura; no se reconstruye patrimonio histórico. La deuda pendiente excluye intereses futuros y otros bienes.

## Copias

**Crear copia local** usa la API de backup SQLite, incluso con WAL activo. **Exportar copia** permite elegir otro destino. Antes de eliminar o restaurar se crea una copia local adicional. No hay rotación automática.

Para restaurar: selecciona una copia → validación de tamaño (máximo 100 MB), aplicación, esquema, integridad y referencias → copia privada estable para vista previa → confirma la sustitución. Antes se conserva el estado actual. Una copia incompatible se rechaza. Solo restaura archivos de confianza.

El CSV usa separador punto y coma, UTF-8 y decimales con coma. Incluye todos los movimientos activos, aunque la pantalla muestre un filtro; neutraliza prefijos de fórmula en campos de texto. No incluye objetivos, presupuestos ni todo el historial: no sirve para restaurar el espacio completo. No hay importación CSV.

Si necesitas retroceder tras una actualización, conserva primero una copia completa. Versiones antiguas pueden rechazar un esquema más nuevo: no sustituyas una base por ensayo y error. Para esta primera publicación no se migra la edición personal anterior.
