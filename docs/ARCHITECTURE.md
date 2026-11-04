# Arquitectura y pruebas

## Aplicación

- `Sources/main.swift`: ciclo AppKit, ventana, WKWebView, puente nativo, archivos, instancia única y modos de comprobación.
- `Sources/Appearance.swift`: preferencias de tema y señales de accesibilidad de NSWorkspace.
- `Sources/Store.swift`: base SQLite, migración 1, validación, reglas financieras, repositorios, copias y CSV.
- `Sources/CSQLite`: puente a sqlite3 del sistema.
- `Resources/web`: HTML/CSS/JS locales. La interfaz llama al puente con mensajes estructurados; el repositorio valida de nuevo. Texto de usuario escapado al representarlo.
- `Resources/web/brand`: geometría del símbolo e identidad; `backgrounds/caudal-flow.svg` es el fondo original público.

La app no abre puertos ni necesita servidor. WebKit usa un data store no persistente. CSP `connect-src 'none'`; navegación restringida al directorio web del bundle. El estado financiero vive únicamente en SQLite, no en localStorage.

## Construcción

```sh
./scripts/build.sh
./scripts/build.sh --dev
```

Swift 5 como modo de lenguaje, destino arm64-apple-macosx13.0 y frameworks del sistema. Se aplican mapas de prefijo para evitar incrustar el directorio personal de compilación. No se enlazan dependencias descargadas. `version.json` es la fuente del número de versión/build. La versión nativa se comunica a la interfaz.

Los iconos ya están incluidos. Para regenerarlos en un Mac:

```sh
mkdir -p build/module-cache
xcrun swift -module-cache-path build/module-cache scripts/icon.swift
iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns
```

## Verificación reproducible

```sh
./tests/run.sh
./tests/run-ui.sh
./tests/isolation.sh
python3 scripts/audit_publication.py --bundle dist/Caudal.app
```

`tests/run.sh` compila el almacén y ejercita céntimos, reglas, errores, persistencia, exportación y restauración con directorios temporales. `tests/run-ui.sh` abre el binario compilado con CAUDAL_DATA bajo build/, rellena formularios reales en WebKit y escribe JSON y capturas; necesita sesión gráfica y termina su proceso al salir. No simula que CI dispone de GUI si no la tiene. `tests/isolation.sh` verifica configuraciones release/dev y arranque vacío con carpetas temporales.

Los informes quedan en build/, excluido de Git. `docs/VERIFICACION.md` resume los resultados reales y sus límites. El análisis de contraste mide tokens densos, no todos los píxeles de paneles transparentes.

No hay refracción nativa propietaria de Apple: el acabado Glass se compone con CSS. Los diálogos no animan opacidad o transformación ni superponen blur, para evitar un fallo observado de composición nativa.
