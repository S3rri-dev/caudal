// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 S3rri-dev y colaboradores.
import AppKit
import Foundation

// Misma geometría que el SVG de la interfaz: un único símbolo para toda la app.
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
let brand=root.appendingPathComponent("Resources/web/brand")
let geometry=try JSONSerialization.jsonObject(with:Data(contentsOf:brand.appendingPathComponent("caudal-paths.json"))) as! [String:Any]
let paths=geometry["paths"] as! [[String:Any]]
let folder=root.appendingPathComponent("build/AppIcon.iconset")
try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
for size in [16,32,64,128,256,512,1024] {
    let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:size,pixelsHigh:size,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:rep)
    let scale=NSAffineTransform();scale.scale(by:CGFloat(size)/1024);scale.concat()
    let face=NSBezierPath(roundedRect:NSRect(x:55,y:55,width:914,height:914),xRadius:210,yRadius:210)
    NSGradient(colors:[NSColor(calibratedRed:0.018,green:0.065,blue:0.035,alpha:1),NSColor(calibratedRed:0.075,green:0.19,blue:0.12,alpha:1)])!.draw(in:face,angle:65)
    NSColor(calibratedRed:0.79,green:0.73,blue:0.52,alpha:0.28).setStroke();face.lineWidth=3;face.stroke()
    NSGraphicsContext.saveGraphicsState();face.addClip()
    NSColor(calibratedRed:0.86,green:0.89,blue:0.70,alpha:0.035).setFill()
    NSBezierPath(ovalIn:NSRect(x:-110,y:610,width:1280,height:620)).fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.saveGraphicsState()
    let placement=NSAffineTransform();placement.translateX(by:166,yBy:858);placement.scaleX(by:2.7,yBy:-2.7);placement.concat()
    let mark=NSBezierPath()
    for item in paths {
        let start=item["start"] as! [Double];mark.move(to:NSPoint(x:start[0],y:start[1]))
        for c in item["curves"] as! [[Double]] {mark.curve(to:NSPoint(x:c[4],y:c[5]),controlPoint1:NSPoint(x:c[0],y:c[1]),controlPoint2:NSPoint(x:c[2],y:c[3]))}
        mark.close()
    }
    NSGradient(colors:[NSColor(calibratedRed:0.86,green:0.76,blue:0.54,alpha:1),NSColor(calibratedRed:0.72,green:0.59,blue:0.34,alpha:1)])!.draw(in:mark,angle:30)
    NSGraphicsContext.restoreGraphicsState();NSGraphicsContext.restoreGraphicsState()
    let png=rep.representation(using:.png,properties:[:])!
    if [16,32,128,256,512].contains(size) {try png.write(to:folder.appendingPathComponent("icon_\(size)x\(size).png"))}
    if size>=32 && [16,32,128,256,512].contains(size/2) {try png.write(to:folder.appendingPathComponent("icon_\(size/2)x\(size/2)@2x.png"))}
    if size==512 {try png.write(to:brand.appendingPathComponent("caudal-icon-512.png"))}
}
