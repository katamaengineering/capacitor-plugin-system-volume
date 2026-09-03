import Foundation
import UIKit
import MediaPlayer
import AVFoundation
import Capacitor
import WebKit

/// One native system-volume slider, mounted into the webview's view tree.
///
/// Wraps an `MPVolumeView` — Apple's own system-volume control — so dragging it
/// sets the OS output volume and the hardware buttons move it. The mounting and
/// frame-sync is the same compositing trick capacitor-plugin-apple-maps uses to
/// overlay a native `MKMapView`; here the overlaid view is the volume slider.
final class SystemVolume: NSObject {
    /// Tag marking the mounted container so the view-tree walk skips it.
    static let sliderTag = 99_981

    let id: String
    private weak var plugin: CAPPlugin?
    private let volumeView = MPVolumeView()
    private var targetView: UIView?
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

    // MARK: - Mounting (ported from capacitor-plugin-apple-maps)

    func mount(rect: CGRect) {
        rebindTargetContainer(rect: rect)
    }

    func updateRender(rect: CGRect) {
        runOnMain {
            let widthEqual = round(Double(self.volumeView.bounds.width)) == round(Double(rect.width))
            let heightEqual = round(Double(self.volumeView.bounds.height)) == round(Double(rect.height))
            if !widthEqual || !heightEqual {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.volumeView.frame.size = rect.size
                CATransaction.commit()
            }
        }
    }

    func rebindTargetContainer(rect: CGRect) {
        runOnMain {
            let refWidth = round(Double(rect.width))
            let refHeight = round(Double(rect.height))
            guard let target = self.getTargetContainer(refWidth: refWidth, refHeight: refHeight) else { return }
            self.targetView = target
            target.tag = SystemVolume.sliderTag
            target.removeAllSubview()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.volumeView.frame = CGRect(origin: .zero, size: rect.size)
            CATransaction.commit()
            target.addSubview(self.volumeView)
        }
    }

    /// Finds the WKWebView child scroll view whose content size matches the bound
    /// element, so the slider can be mounted into it. Must run on the main thread.
    private func getTargetContainer(refWidth: Double, refHeight: Double) -> UIView? {
        guard let webView = plugin?.bridge?.webView else { return nil }
        for item in webView.getAllSubViews() {
            guard let scrollView = item as? UIScrollView else { continue }
            let childScrollClass = NSClassFromString("WKChildScrollView")
            let scrollClass = NSClassFromString("WKScrollView")
            let isChildScroll = (childScrollClass.map { item.isKind(of: $0) } ?? false)
                || (scrollClass.map { item.isKind(of: $0) } ?? false)
            let isBridgeScroll = item.isEqual(webView.scrollView)
            if isChildScroll && !isBridgeScroll {
                scrollView.isScrollEnabled = true
                let width = Double(scrollView.contentSize.width)
                let height = Double(scrollView.contentSize.height)
                let widthEqual = width == refWidth
                let heightEqual = floor(height / 2) == refHeight || ceil(height / 2) == refHeight
                if widthEqual && heightEqual && item.tag < (self.targetView?.tag ?? SystemVolume.sliderTag) {
                    // The slider is a UISlider, which tracks touches directly. A
                    // UIScrollView delays content touches and cancels them the
                    // moment it reads a drag as a scroll, which steals every drag
                    // from the slider. Turn both off so drags reach the slider.
                    scrollView.delaysContentTouches = false
                    scrollView.canCancelContentTouches = false
                    return item
                }
            }
        }
        return nil
    }

    func teardown() {
        runOnMain {
            self.volumeObservation?.invalidate()
            self.volumeObservation = nil
            self.volumeView.removeFromSuperview()
            self.targetView?.tag = 0
            self.targetView = nil
        }
    }

    private func runOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }
}
