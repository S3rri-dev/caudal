# Especificación pública · Caudal 0.4

Aplicación local de finanzas personales para Mac Apple Silicon. Primera publicación de prueba; registro manual, EUR, español, fechas Europe/Madrid. No hay servidor ni cuenta de acceso.

## Alcance existente

Ocho vistas: Resumen, Movimientos, Cuentas, Presupuestos, Ahorro y objetivos, Deudas, Informes y Ajustes/datos. Crear/editar/eliminar entidades conservando referencias; movimientos con borrado lógico y deshacer. Exportar CSV y copia completa; restaurar con validación y vista previa.

## Criterios financieros

1. Importes enteros en céntimos. Movimiento positivo, fecha válida hasta hoy y referencias coherentes.
2. Saldos iniciales como base, sin computar ingreso y sin fecha de apertura propia.
3. Transferencias entre cuentas distintas; saldo total, ingresos y gastos no se alteran por la transferencia.
4. Un presupuesto por mes/categoría de gasto. Incluye consumo e intereses; excluye principal y transferencias.
5. Reserva virtual por objetivo: no mueve dinero; no se aumenta por encima del saldo disponible ni de la meta. Gastos posteriores pueden dejarla sin cobertura y se informa sin ocultar registros.
6. Deuda existente: pasivo sin entrada de dinero. Nueva disposición: cuenta y principal aumentan sin ingreso.
7. Cuota: total y principal explícitos, principal ≤ total y pendiente; diferencia = intereses/comisiones. No generar pagos por una fecha ni calcular intereses futuros.
8. Validar pagos por orden temporal; rechazar ediciones/borrados que invaliden cuotas posteriores.
9. Saldo/deuda actuales; ingresos y gastos filtrados por mes. Variación = ingresos − gastos − principal + préstamos recibidos.
10. Copia consistente SQLite; validación de aplicación, esquema, integridad y referencias antes de reemplazar; copia del estado anterior.

## Distribución y diseño

Caudal pública y Dev con IDs y almacenamiento propios, separados de ediciones personales anteriores. La descarga empieza vacía; categorías predeterminadas no crean cuentas ni dinero. Sin recursos de red. Fondo original público, C de ondas y cristal CSS con temas claro/oscuro/sistema. Preferencias de accesibilidad sin modificar macOS.

## Aplazado

Conexión bancaria, inversiones, sincronización, IA, móvil, multimoneda, importación CSV y pagos recurrentes. No hay fecha comprometida. No se presentan como funciones existentes.

## Validación y límites

Pruebas de almacén, UI WebKit y aislamiento, más revisión nativa. La facilidad de uso diario y otras plataformas requieren pruebas independientes. No se afirma auditoría financiera, de seguridad o WCAG completa. Objetivo mínimo de compilación no equivale a compatibilidad probada.
