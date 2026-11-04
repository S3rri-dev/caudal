# Publicar una versión

Solo el mantenedor autorizado publica en S3rri-dev/caudal. Usa su identidad GitHub y correo noreply; no cambies configuraciones globales ni incluyas credenciales en archivos, URLs o commits.

1. Actualiza version.json, CHANGELOG, documentación y notas en docs/releases/. Revisa procedencia y licencias de recursos. Solo datos ficticios.
2. Compila y verifica: `./scripts/build.sh`, `./tests/run.sh`, `./tests/run-ui.sh`, `./tests/isolation.sh`. Revisa ventana nativa, primer arranque y formularios con datos aislados.
3. Ejecuta `python3 scripts/audit_publication.py --history --bundle dist/Caudal.app`. Revisa también nombres, metadatos, contenido de capturas y Git. El escáner no reemplaza una revisión humana.
4. Confirma la copia pública limpia. Compila otra vez desde ese commit para incluirlo en Info.plist. Ejecuta `./scripts/package.sh`: exige árbol limpio, bundle ligado a HEAD y resultado UI correcto. No sobrescribe paquetes existentes.
5. El paquete contiene app ZIP, DMG con acceso a Aplicaciones y avisos, ZIP de fuentes del commit exacto, manifiesto y SHA256SUMS. El manifiesto registra origen local o Actions; no implica reproducción binaria exacta entre SDK diferentes.
6. Crea y revisa un borrador. Comprueba título, tag/commit, notas, hashes y adjuntos. Descárgalos, verifica hashes y fuentes, monta el DMG en solo lectura, comprueba firma y arranca con CAUDAL_DATA aislado.
7. Publica el borrador autorizado. Descarga de nuevo sin autenticación y repite integridad, montaje y arranque. No declares que eso prueba Gatekeeper en un segundo Mac limpio.
8. Revisa Actions y documenta su estado real. Una cola no es una prueba superada. Puedes entregar el paquete local comprobado si se identifica expresamente esa procedencia.

CI se ejecuta en push/PR para macOS 15 y 26 ARM64. El workflow manual de release toma una etiqueta existente, valida versión, ejecuta las pruebas, conserva artefactos y crea solo un borrador. Rechaza una release ya existente: no sustituye binarios publicados. Acciones fijadas por SHA, checkout sin persistir credenciales y permisos de escritura limitados al job de publicación.

## Firma y retirada

La distribución inicial tiene firma ad hoc. No afirma Developer ID, notarización, App Sandbox o compatibilidad con Intel. No usa secretos de firma ni certificados.

Si aparece un fallo de pérdida de datos o una discrepancia de hash, retira la recomendación de descarga y documenta la incidencia; no reemplaces silenciosamente artefactos bajo la misma versión. Prepara una versión corregida y conserva hashes/procedencia. Los usuarios deben exportar una copia antes de actualizar y conservarla antes de retroceder. No modificar ni borrar sus datos como parte de una retirada.
