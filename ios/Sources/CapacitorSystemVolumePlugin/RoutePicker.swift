import Foundation
import UIKit
import AVKit
import Capacitor

/// A native AirPlay route button (`AVRoutePickerView`) overlaid on the webview.
/// Tapping it opens the system output-route picker (AirPlay speakers, Apple TV,
/// Bluetooth, etc.) — Apple handles all of that; there is nothing to wire from JS.
///
/// Overlaid as a plain top-level webview subview at the bound element's rect, the
/// same way SystemVolume is (see that file for why a direct overlay, not the
/// child scroll view).
final class RoutePicker: NSObject, WebOverlay {
    private weak var plugin: CAPPlugin?
    private let pickerView = AVRoutePickerView()

    init(plugin: CAPPlugin, style: JSObject?) {
        self.plugin = plugin
        super.init()
        pickerView.backgroundColor = .clear
        // Audio-only: don't bias the picker toward video-capable routes.
        pickerView.prioritizesVideoDevices = false
        applyStyle(style)
    }

    func applyStyle(_ obj: JSObject?) {
        let o = obj ?? [:]
        if let tint = (o["tintColor"] as? String).flatMap({ UIColor(cssHex: $0) }) {
            pickerView.tintColor = tint
        }
        if let active = (o["activeTintColor"] as? String).flatMap({ UIColor(cssHex: $0) }) {
            pickerView.activeTintColor = active
        }
    }

    func setFrame(rect: CGRect) {
        runOnMain {
            guard let webView = self.plugin?.bridge?.webView else { return }
            if self.pickerView.superview !== webView {
                self.pickerView.removeFromSuperview()
                webView.addSubview(self.pickerView)
            }
            webView.bringSubviewToFront(self.pickerView)
            self.pickerView.frame = rect
        }
    }

    func teardown() {
        runOnMain { self.pickerView.removeFromSuperview() }
    }

    private func runOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }
}
