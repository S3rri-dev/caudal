// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 S3rri-dev y colaboradores.
import AppKit
let width=2400, height=1440
let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:width,pixelsHigh:height,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:rep)
let bounds=NSRect(x:0,y:0,width:width,height:height)
NSGradient(colors:[NSColor(calibratedRed:0.012,green:0.035,blue:0.02,alpha:1),NSColor(calibratedRed:0.06,green:0.14,blue:0.09,alpha:1)])!.draw(in:bounds,angle:35)
let gold=NSColor(calibratedRed:0.85,green:0.76,blue:0.55,alpha:1)
let ivory=NSColor(calibratedRed:0.96,green:0.95,blue:0.91,alpha:1)
let muted=NSColor(calibratedRed:0.64,green:0.71,blue:0.63,alpha:1)
func text(_ string:String,_ x:CGFloat,_ y:CGFloat,_ size:CGFloat,_ color:NSColor,_ serif:Bool=false){
 let font=serif ? NSFont(name:"Baskerville",size:size)! : NSFont.systemFont(ofSize:size,weight:.regular)
 (string as NSString).draw(at:NSPoint(x:x,y:y),withAttributes:[.font:font,.foregroundColor:color])
}
let curve=NSBezierPath();curve.move(to:NSPoint(x:-200,y:30));curve.curve(to:NSPoint(x:2550,y:1220),controlPoint1:NSPoint(x:1200,y:1020),controlPoint2:NSPoint(x:1600,y:-360));curve.lineWidth=1.5;gold.withAlphaComponent(0.18).setStroke();curve.stroke()
NSImage(contentsOfFile:"Resources/web/brand/caudal-icon-512.png")!.draw(in:NSRect(x:118,y:1180,width:125,height:125))
text("Caudal",270,1197,84,ivory,true)
text("TU DINERO, CON PERSPECTIVA.",132,1100,22,gold)
text("Un espacio propio",132,933,94,ivory,true)
text("para tus finanzas.",132,825,94,ivory,true)
text("Ingresos. Gastos. Ahorro. Deudas.",135,742,29,muted)
text("Registro manual · Sin cuenta · Todo en tu Mac",135,690,25,muted)
let target=NSRect(x:1060,y:250,width:1230,height:803)
let shadow=NSShadow();shadow.shadowColor=NSColor.black.withAlphaComponent(0.65);shadow.shadowBlurRadius=70;shadow.shadowOffset=NSSize(width:0,height:-25)
NSGraphicsContext.saveGraphicsState();shadow.set();let frame=NSBezierPath(roundedRect:target.insetBy(dx:-2,dy:-2),xRadius:22,yRadius:22);NSColor(calibratedRed:0.20,green:0.29,blue:0.19,alpha:1).setFill();frame.fill();NSGraphicsContext.restoreGraphicsState()
NSGraphicsContext.saveGraphicsState();NSBezierPath(roundedRect:target,xRadius:20,yRadius:20).addClip();NSImage(contentsOfFile:"docs/images/overview-dark.jpg")!.draw(in:target);NSGraphicsContext.restoreGraphicsState()
let pill=NSBezierPath(roundedRect:NSRect(x:135,y:504,width:408,height:65),xRadius:32,yRadius:32);gold.setFill();pill.fill();text("CAUDAL PARA MAC",171,526,22,NSColor(calibratedRed:0.04,green:0.11,blue:0.065,alpha:1))
text("APPLE SILICON  /  LOCAL  /  CÓDIGO ABIERTO",135,139,18,gold)
text("S3rri-dev/caudal",135,93,23,muted)
text("COMPOSICIÓN PROMOCIONAL · DATOS FICTICIOS",1640,137,15,muted)
NSGraphicsContext.restoreGraphicsState()
try rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"docs/images/hero.png"))
