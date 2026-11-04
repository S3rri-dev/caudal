// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 S3rri-dev y colaboradores.
import AppKit

extension AppDelegate {
    var appearanceFile: URL { dataDirectory.appendingPathComponent("apariencia.json") }
    func appearancePreferences() -> Row {
        let settings = (try? Data(contentsOf:appearanceFile)).flatMap{try? JSONSerialization.jsonObject(with:$0) as? Row} ?? [:]
        let candidate = str(settings,"theme")
        let theme = ["system","light","dark"].contains(candidate) ? candidate : "dark"
        let workspace = NSWorkspace.shared
        return ["theme":theme,"reduceTransparency":workspace.accessibilityDisplayShouldReduceTransparency,
                "reduceMotion":workspace.accessibilityDisplayShouldReduceMotion,
                "increaseContrast":workspace.accessibilityDisplayShouldIncreaseContrast]
    }
    func setAppearance(_ theme: String) throws -> Row {
        guard ["system","light","dark"].contains(theme) else {throw problem("Selecciona una apariencia válida.")}
        let data = try JSONSerialization.data(withJSONObject:["theme":theme],options:[.sortedKeys])
        try data.write(to:appearanceFile,options:.atomic)
        try FileManager.default.setAttributes([.posixPermissions:0o600],ofItemAtPath:appearanceFile.path)
        applyNativeAppearance(); return appearancePreferences()
    }
    func applyNativeAppearance() {
        switch str(appearancePreferences(),"theme") {
        case "light": NSApp.appearance = NSAppearance(named:.aqua)
        case "dark": NSApp.appearance = NSAppearance(named:.darkAqua)
        default: NSApp.appearance = nil
        }
        window?.appearance = nil
        let dark = NSApp.effectiveAppearance.bestMatch(from:[.darkAqua,.aqua]) == .darkAqua
        let color = dark ? NSColor(calibratedRed:0.012,green:0.028,blue:0.016,alpha:1) : NSColor(calibratedRed:0.91,green:0.91,blue:0.85,alpha:1)
        window?.backgroundColor = color; web?.underPageBackgroundColor = color
    }
    @objc func accessibilityOptionsChanged(_ notification: Notification) {
        guard let value = try? json(appearancePreferences()) else {return}
        web?.evaluateJavaScript("window.appearanceUpdate?.(\(value))")
    }
}
