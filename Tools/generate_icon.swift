import AppKit

/// Code-native artwork; no external assets or image-generation dependency.
let folder = URL(fileURLWithPath: "App/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
var entries: [[String: String]] = []
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: pixels * 4, bitsPerPixel: 32,
        ) else { fatalError("Cannot allocate icon bitmap") }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let transform = NSAffineTransform()
        transform.scale(by: CGFloat(pixels) / 1024)
        transform.concat()
        let background = NSBezierPath(
            roundedRect: NSRect(x: 50, y: 50, width: 924, height: 924), xRadius: 205, yRadius: 205,
        )
        NSColor(calibratedRed: 0.08, green: 0.17, blue: 0.22, alpha: 1).setFill()
        background.fill()
        NSColor(calibratedRed: 0.35, green: 0.83, blue: 0.87, alpha: 1).setStroke()
        let ring = NSBezierPath()
        ring.lineWidth = 76
        ring.lineCapStyle = .round
        ring.appendArc(
            withCenter: NSPoint(x: 512, y: 485), radius: 248, startAngle: 52, endAngle: 128,
            clockwise: true,
        )
        ring.stroke()
        let stem = NSBezierPath()
        stem.lineWidth = 76
        stem.lineCapStyle = .round
        stem.move(to: NSPoint(x: 512, y: 790))
        stem.line(to: NSPoint(x: 512, y: 515))
        stem.stroke()
        NSGraphicsContext.restoreGraphicsState()
        let name = "icon_\(size)x\(size)@\(scale)x.png"
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            fatalError("Cannot encode icon PNG")
        }
        try png.write(
            to: folder.appendingPathComponent(name),
        )
        entries.append([
            "idiom": "mac", "size": "\(size)x\(size)", "scale": "\(scale)x", "filename": name,
        ])
    }
}

let contents: [String: Any] = ["images": entries, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]).write(
    to: folder.appendingPathComponent("Contents.json"),
)
