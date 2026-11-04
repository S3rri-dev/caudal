# Contribuir

Abre una incidencia antes de cambios amplios y consulta README.md, AGENTS.md y docs/ESPECIFICACION.md. Mantén los cambios acotados y las reglas financieras verificables.

Compila con `./scripts/build.sh --dev`. Caudal Dev utiliza identificador y datos propios; no desarrolles contra un espacio financiero real. Instala herramientas solo si faltan y con conocimiento del entorno; la app no necesita paquetes externos.

Antes de una pull request:

```sh
./scripts/build.sh
./tests/run.sh
./tests/run-ui.sh
./tests/isolation.sh
python3 scripts/audit_publication.py --bundle dist/Caudal.app
```

Revisa la ventana nativa cuando cambies composición visual. Las capturas internas no demuestran por sí solas que macOS dibuje correctamente un diálogo. Documenta lo ejecutado y las limitaciones; no inventes CI o compatibilidad.

Usa datos ficticios y no adjuntes bases, saldos reales, credenciales o rutas personales. No publiques artefactos de build/dist en commits. Los informes van en build/. Describe el problema, el comportamiento final y la validación en la PR.

Las contribuciones de código se aceptan bajo GPL-3.0-or-later. Conserva autoría y licencias de terceros, documenta la procedencia de recursos y respeta TRADEMARKS.md. No se exige ceder la autoría ni firmar un CLA.
