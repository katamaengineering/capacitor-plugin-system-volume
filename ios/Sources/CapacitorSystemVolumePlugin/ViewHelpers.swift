import Foundation
import UIKit
import WebKit
import Capacitor

// MARK: - View-tree + touch-routing helpers
//
// The compositing glue that mounts a native view into the WKWebView's view tree
// and routes touches down to it. Ported from @capacitor/google-maps via
// capacitor-plugin-apple-maps — the same trick both use to overlay a native
// view on the webview.

// MARK: - WKWebView touch routing
//
// Routes touches that land on a WKChildScrollView down to the native view
// mounted inside it (without this the slider would receive no drags).
extension WKWebView {
    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var hitView = super.hitTest(point, with: event)
        if let childScrollClass = NSClassFromString("WKChildScrollView"),
           let candidate = hitView, candidate.isKind(of: childScrollClass) {
            for item in candidate.subviews.reversed() {
                let converted = item.convert(point, from: self)
                if let inner = item.hitTest(converted, with: event) {
                    hitView = inner
                    break
                }
            }
        }
        return hitView
    }
}

// MARK: - View tree helpers

extension UIView {
    private static var allSubviews: [UIView] = []

    private func viewArray(root: UIView) -> [UIView] {
        var index = root.tag
        for view in root.subviews {
            if view.tag == SystemVolume.sliderTag { continue }
            view.tag = index
            UIView.allSubviews.append(view)
            _ = viewArray(root: view)
            index += 1
        }
        return UIView.allSubviews
    }

    func getAllSubViews() -> [UIView] {
        UIView.allSubviews = []
        return viewArray(root: self).reversed()
    }

    func removeAllSubview() {
        subviews.forEach { $0.removeFromSuperview() }
    }
}

// MARK: - JS bridging

extension CGRect {
    static func fromJSObject(_ obj: JSObject) -> CGRect {
        let x = obj["x"] as? Double ?? 0
        let y = obj["y"] as? Double ?? 0
        let width = obj["width"] as? Double ?? 0
        let height = obj["height"] as? Double ?? 0
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - Styling helpers

extension UIColor {
    /// Parse a CSS hex string (`#RGB`, `#RRGGBB`, or `#RRGGBBAA`). Returns nil on
    /// anything unparseable so callers can fall back to a default.
    convenience init?(cssHex: String) {
        var hex = cssHex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        guard hex.count == 6 || hex.count == 8, let value = UInt64(hex, radix: 16) else { return nil }
        let hasAlpha = hex.count == 8
        let r = CGFloat((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let g = CGFloat((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let b = CGFloat((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let a = hasAlpha ? CGFloat(value & 0xFF) / 255 : 1
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    /// A 1×1 resizable image of this colour, for a slider track.
    func trackImage() -> UIImage {
        let size = CGSize(width: 1, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            self.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }.resizableImage(withCapInsets: .zero)
    }

    /// A filled circle of this colour, for a slider thumb.
    func thumbImage(radius: CGFloat) -> UIImage {
        let size = CGSize(width: radius, height: radius)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            self.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
    }
}
