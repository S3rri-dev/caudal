// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 S3rri-dev y colaboradores.
import AppKit
import WebKit
import UniformTypeIdentifiers
import Darwin

let appName = Bundle.main.object(forInfoDictionaryKey:"CFBundleDisplayName") as? String ?? "Caudal Dev"
let appVersion = Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String ?? "0.4.0"
let dataFolder = Bundle.main.object(forInfoDictionaryKey:"CaudalDataFolder") as? String ?? "Caudal Dev"
let testDirectory = ProcessInfo.processInfo.environment["CAUDAL_DATA"]
let dataDirectory = testDirectory.map{URL(fileURLWithPath:$0)} ?? FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent(dataFolder)
let resources = Bundle.main.resourceURL ?? URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("Resources")

final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    var window: NSWindow!; var web: WKWebView!; var store: Store!; var instanceFD: Int32 = -1
    var restoreCandidate: String?; var restorePreviewPath: String?
    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            try FileManager.default.createDirectory(at:dataDirectory,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700])
            instanceFD = Darwin.open(dataDirectory.appendingPathComponent("instance.lock").path,O_CREAT|O_RDWR,0o600)
            guard instanceFD >= 0, flock(instanceFD, LOCK_EX|LOCK_NB) == 0 else { throw problem("Caudal ya está abierta con estos datos.") }
            store = try Store(directory:dataDirectory)
            NSApp.applicationIconImage = NSImage(contentsOf:resources.appendingPathComponent("web/brand/caudal-icon-512.png"))
            let config = WKWebViewConfiguration(); config.userContentController.add(self,name:"native")
            config.websiteDataStore = .nonPersistent()
            web = WKWebView(frame:.zero,configuration:config); web.navigationDelegate = self
            web.underPageBackgroundColor = NSColor(calibratedRed:0.965,green:0.969,blue:0.957,alpha:1)
            window = NSWindow(contentRect:NSRect(x:0,y:0,width:1440,height:940),styleMask:[.titled,.closable,.miniaturizable,.resizable,.fullSizeContentView],backing:.buffered,defer:false)
            window.title = testDirectory == nil ? appName : "\(appName) · PRUEBAS"
            window.minSize = NSSize(width:1100,height:740); window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            applyNativeAppearance()
            window.contentView = web; window.center(); window.makeKeyAndOrderFront(nil)
            let menu = NSMenu(); let appItem = NSMenuItem(); menu.addItem(appItem); let appMenu = NSMenu()
            appMenu.addItem(withTitle:"Acerca de \(appName)",action:#selector(about),keyEquivalent:"")
            appMenu.addItem(.separator()); appMenu.addItem(withTitle:"Ocultar \(appName)",action:#selector(NSApplication.hide(_:)),keyEquivalent:"h")
            appMenu.addItem(withTitle:"Salir de \(appName)",action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q"); appItem.submenu = appMenu
            let editItem = NSMenuItem(); menu.addItem(editItem); let editMenu = NSMenu(title:"Edición")
            for (title,key,selector) in [("Deshacer","z","undo:"),("Cortar","x","cut:"),("Copiar","c","copy:"),("Pegar","v","paste:"),("Seleccionar todo","a","selectAll:")] {editMenu.addItem(withTitle:title,action:Selector(selector),keyEquivalent:key)}
            editItem.submenu = editMenu; NSApp.mainMenu = menu
            web.loadFileURL(resources.appendingPathComponent("web/index.html"),allowingReadAccessTo:resources.appendingPathComponent("web"))
            NSWorkspace.shared.notificationCenter.addObserver(self,selector:#selector(accessibilityOptionsChanged(_:)),name:NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,object:nil)
            NSApp.activate(ignoringOtherApps:true)
        } catch { let a = NSAlert(); a.messageText = "No se pudo abrir Caudal"; a.informativeText = error.localizedDescription; a.runModal(); NSApp.terminate(nil) }
    }
    @objc func about() { NSApp.orderFrontStandardAboutPanel(options:[.applicationName:appName,.applicationVersion:appVersion,.credits:NSAttributedString(string:"Copyright © 2026 S3rri-dev y colaboradores.\nCódigo GPL-3.0-or-later, sin garantía.\nNombre y logo reservados: TRADEMARKS.md.\nLicencia y avisos incluidos en Contents/Resources.")]) }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication) -> Bool { true }
    func applicationWillTerminate(_ notification: Notification) {if let path = restoreCandidate {try? FileManager.default.removeItem(atPath:path)}}
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy)->Void) {
        let url = action.request.url
        decisionHandler(url?.isFileURL == true && url!.standardizedFileURL.path.hasPrefix(resources.appendingPathComponent("web").standardizedFileURL.path+"/") ? .allow : .cancel)
    }
    func reply(_ id: Int, _ result: Any = true, error: String? = nil) {
        let payload: Row = error.map{["id":id,"ok":false,"error":$0]} ?? ["id":id,"ok":true,"result":result]
        guard let value = try? json(payload) else {return}; web.evaluateJavaScript("window.nativeReply(\(value))")
    }
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, message.frameInfo.request.url?.isFileURL == true,
              let p = message.body as? Row, let id = p["id"] as? Int else {return}
        let action = str(p,"action"), params = p["params"] as? Row ?? [:]
        do {
            switch action {
            case "snapshot": var value = try store.snapshot(); value["testing"] = testDirectory != nil; value["appName"] = appName; value["version"] = appVersion; value["appearance"] = appearancePreferences(); reply(id,value)
            case "appearance": reply(id,try setAppearance(str(params,"theme")))
            case "save": reply(id,try store.save(str(params,"entity"),params["value"] as? Row ?? [:]))
            case "delete": try store.delete(str(params,"entity"),str(params,"id")); reply(id)
            case "restoreMovement": try store.delete("movement",str(params,"id"),restore:true); reply(id)
            case "backup": reply(id,try store.backup())
            case "exportBackup","exportCSV","chooseRestore": filePanel(action,id)
            case "applyRestore":
                guard let candidate = restoreCandidate else {throw problem("Selecciona primero una copia y revisa su contenido.")}
                try store.restore(candidate); try? FileManager.default.removeItem(atPath:candidate); restoreCandidate = nil; reply(id)
            case "cancelRestore":
                if let path = restoreCandidate {try? FileManager.default.removeItem(atPath:path)}; restoreCandidate = nil; reply(id)
            case "showData": NSWorkspace.shared.open(dataDirectory); reply(id)
            case "uiTestResult":
                guard let dir = testDirectory, CommandLine.arguments.contains("--ui-test") else {throw problem("Modo de prueba no habilitado.")}
                try json(params).write(to:URL(fileURLWithPath:dir).appendingPathComponent("ui-result.json"),atomically:true,encoding:.utf8); reply(id)
            case "uiCapture":
                guard let dir = testDirectory, CommandLine.arguments.contains("--ui-test"), str(params,"name").range(of:"^[a-z-]+$",options:.regularExpression) != nil else {throw problem("Captura de prueba no habilitada.")}
                web.takeSnapshot(with:nil) {snapshot,error in
                    guard let image = snapshot, let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data:tiff), let png = bitmap.representation(using:.png,properties:[:]) else {self.reply(id,error:"No se pudo capturar la vista.");return}
                    do {let path = URL(fileURLWithPath:dir).appendingPathComponent(str(params,"name")+".png"); try png.write(to:path);self.reply(id,path.path)}catch{self.reply(id,error:error.localizedDescription)}
                }
            case "uiResize":
                guard testDirectory != nil, CommandLine.arguments.contains("--ui-test"), [1100,1440].contains(Int(num(params,"width"))), [740,940].contains(Int(num(params,"height"))) else {throw problem("Tamaño de prueba no habilitado.")}
                window.setContentSize(NSSize(width:Int(num(params,"width")),height:Int(num(params,"height"))));reply(id)
            default: throw problem("Operación desconocida.")
            }
        } catch {
            let raw = error.localizedDescription
            reply(id,error:raw.contains("FOREIGN KEY") ? "Este elemento tiene movimientos o presupuestos asociados. Conserva su historial o elimina primero esas referencias." : raw)
        }
    }
    func filePanel(_ action: String, _ id: Int) {
        let panel: NSSavePanel = action == "chooseRestore" ? NSOpenPanel() : NSSavePanel()
        panel.title = appName
        if let p = panel as? NSOpenPanel {p.canChooseDirectories = false; p.canChooseFiles = true; p.allowsMultipleSelection = false}
        else {panel.nameFieldStringValue = "Caudal-\(Dates.day()).\(action == "exportCSV" ? "csv" : "sqlite")"}
        panel.beginSheetModal(for:window) {response in
            guard response == .OK, let url = panel.url else {self.reply(id,false);return}
            do {
                if action != "chooseRestore", url.resolvingSymlinksInPath().path.hasPrefix(dataDirectory.resolvingSymlinksInPath().path+"/") {throw problem("Exporta fuera de la carpeta interna de datos para proteger la base activa y sus copias.")}
                switch action {
                case "exportCSV": try self.store.csv().write(to:url,atomically:true,encoding:.utf8); self.reply(id,url.path)
                case "exportBackup":
                    // NSSavePanel asks before replacing. Stage a consistent backup before replacing the chosen file.
                    let staged = try self.store.backup()
                    let source = try Database(staged,readonly:true)
                    guard url.standardizedFileURL != dataDirectory.appendingPathComponent("caudal.sqlite").standardizedFileURL else {throw problem("Elige un archivo distinto de la base activa.")}
                    let temporary = url.deletingLastPathComponent().appendingPathComponent(".caudal-\(UUID().uuidString).sqlite")
                    try source.backup(temporary.path)
                    if FileManager.default.fileExists(atPath:url.path) {_ = try FileManager.default.replaceItemAt(url,withItemAt:temporary)}
                    else {try FileManager.default.moveItem(at:temporary,to:url)}
                    self.reply(id,url.path)
                case "chooseRestore":
                    _ = try self.store.previewRestore(url.path)
                    if let old = self.restoreCandidate {try? FileManager.default.removeItem(atPath:old)}
                    let stage = dataDirectory.appendingPathComponent("restore-\(UUID().uuidString).sqlite")
                    let source = try Database(url.path,readonly:true); try source.backup(stage.path)
                    let info = try self.store.previewRestore(stage.path)
                    self.restoreCandidate = stage.path
                    self.reply(id,["summary":info,"name":url.lastPathComponent])
                default: break
                }
            } catch {self.reply(id,error:error.localizedDescription)}
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if testDirectory != nil && CommandLine.arguments.contains("--ui-test") {
            DispatchQueue.main.asyncAfter(deadline:.now()+1) {
                if let code = try? String(contentsOf:resources.appendingPathComponent("web/ui-check.js"),encoding:.utf8) {self.web.evaluateJavaScript(code)}
            }
        }
    }
}

if CommandLine.arguments.contains("--check") {
    guard testDirectory != nil else {fputs("--check exige CAUDAL_DATA con una carpeta aislada.\n",stderr);exit(2)}
    do {
        let store = try Store(directory:dataDirectory)
        let counts = try ["accounts","movements","budgets","goals","debts"].reduce(into:Row()) { result,table in result[table] = try store.db.rows("SELECT * FROM \(table)").count }
        print(try json(["ok":true,"app":appName,"version":appVersion,"defaultDataFolder":dataFolder,"counts":counts,"totals":try store.totals()]))
        exit(0)
    } catch {fputs("\(error.localizedDescription)\n",stderr);exit(1)}
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.regular); app.delegate = delegate; app.run()
