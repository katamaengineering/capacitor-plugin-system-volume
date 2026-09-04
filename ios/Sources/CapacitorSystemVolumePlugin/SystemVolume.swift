import Foundation
import UIKit
import MediaPlayer
import AVFoundation
import Capacitor
import WebKit

/// One native system-volume slider, overlaid on the webview.
///
/// Wraps an `MPVolumeView` — Apple's own system-volume control — so dragging it
/// sets the OS output volume and the hardware buttons move it.
///
/// The slider is added as a plain top-level subview of the `WKWebView`, positioned
/// at the bound element's rect. It is deliberately NOT mounted inside WebKit's
/// child scroll view (the way a native map overlay is): an `MPVolumeView`'s slider
/// tracks touches directly, and any scroll view between the finger and the control
/// delays, cancels, or scrolls away that drag. A direct overlay keeps the touch
/// path clean. The trade-off is that it does not clip or scroll with page content
/// on its own — the host repositions it through the onScroll/onResize hooks.
final class SystemVolume: NSObject, WebOverlay {
    let id: String
    private weak var plugin: CAPPlugin?
    private let volumeView = MPVolumeView()
    private var style: VolumeStyle
    private var volumeObservation: NSKeyValueObservation?

    /// Fires when the system output volume changes, `0`–`1`.
    var onVolumeChange: ((Float) -> Void)?

    struct VolumeStyle {
        var minimumTrackColor: UIColor?
        var maximumTrackColor: UIColor?
        var thumbColor: UIColor?
        var thumbRadius: CGFloat

        init(_ obj: JSObject?) {
            let o = obj ?? [:]
            minimumTrackColor = (o["minimumTrackColor"] as? String).flatMap { UIColor(cssHex: $0) }
            maximumTrackColor = (o["maximumTrackColor"] as? String).flatMap { UIColor(cssHex: $0) }
            thumbColor = (o["thumbColor"] as? String).flatMap { UIColor(cssHex: $0) }
            thumbRadius = CGFloat(o["thumbRadius"] as? Double ?? 16)
        }
    }

    init(id: String, plugin: CAPPlugin, style: JSObject?) {
        self.id = id
        self.plugin = plugin
        self.style = VolumeStyle(style)
        super.init()
        configureVolumeView()
        observeSystemVolume()
    }

    // MARK: - Setup

    private func configureVolumeView() {
        // Hide AirPlay routing — this control is only about volume.
        volumeView.showsRouteButton = false
        volumeView.showsVolumeSlider = true
        volumeView.backgroundColor = .clear
        applyStyle()
    }

    private func applyStyle() {
        if let color = style.minimumTrackColor {
            volumeView.setMinimumVolumeSliderImage(color.trackImage(), for: .normal)
        }
        if let color = style.maximumTrackColor {
            volumeView.setMaximumVolumeSliderImage(color.trackImage(), for: .normal)
        }
        if let color = style.thumbColor {
            let thumb = color.thumbImage(radius: style.thumbRadius)
            volumeView.setVolumeThumbImage(thumb, for: .normal)
            volumeView.setVolumeThumbImage(thumb, for: .highlighted)
        }
    }

    func updateStyle(_ obj: JSObject?) {
        runOnMain {
            self.style = VolumeStyle(obj)
            self.applyStyle()
        }
    }

    private func observeSystemVolume() {
        let session = AVAudioSession.sharedInstance()
        volumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            if let value = change.newValue { self?.onVolumeChange?(value) }
        }
    }

    func currentVolume() -> Float {
        return AVAudioSession.sharedInstance().outputVolume
    }

    // MARK: - Mounting

    /// Place the slider at `rect` (the bound element's CSS-pixel rect, which maps
    /// 1:1 to the webview's point coordinates) as a top-level webview subview.
    func setFrame(rect: CGRect) {
        runOnMain {
            guard let webView = self.plugin?.bridge?.webView else { return }
            if self.volumeView.superview !== webView {
                self.volumeView.removeFromSuperview()
                webView.addSubview(self.volumeView)
            }
            // Keep it above the web content so it receives touches.
            webView.bringSubviewToFront(self.volumeView)
            self.volumeView.frame = rect
        }
    }

    func teardown() {
        runOnMain {
            self.volumeObservation?.invalidate()
            self.volumeObservation = nil
            self.volumeView.removeFromSuperview()
        }
    }

    private func runOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }
}
